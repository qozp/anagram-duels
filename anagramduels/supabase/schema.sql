-- ============================================================
-- Anagram Duels — Supabase Schema
-- Run this in the Supabase SQL editor (Database → SQL Editor).
-- ============================================================

-- ──────────────────────────────────────────
-- Extensions
-- ──────────────────────────────────────────
create extension if not exists "uuid-ossp";

-- ──────────────────────────────────────────
-- Profiles (extends Supabase auth.users)
-- ──────────────────────────────────────────
create table if not exists public.profiles (
    id                uuid         primary key references auth.users(id) on delete cascade,
    username          text         not null unique,
    avatar_url        text,
    wins              integer      not null default 0,
    losses            integer      not null default 0,
    total_words_found integer      not null default 0,
    created_at        timestamptz  not null default now(),
    updated_at        timestamptz  not null default now()
);

-- Auto-update updated_at
create or replace function public.handle_updated_at()
returns trigger language plpgsql as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger profiles_updated_at
    before update on public.profiles
    for each row execute function public.handle_updated_at();

-- ──────────────────────────────────────────
-- Matches
-- ──────────────────────────────────────────
create table if not exists public.matches (
    id               uuid         primary key default uuid_generate_v4(),
    player_one_id    uuid         not null references public.profiles(id),
    player_two_id    uuid         references public.profiles(id),
    status           text         not null default 'waiting'
                                  check (status in ('waiting','active','completed','abandoned')),
    mode             text         not null default 'time_based'
                                  check (mode in ('time_based','target_score','target_word_count')),
    base_word        text         not null,
    letters          text[]       not null,      -- shuffled letter array shown to both players
    player_one_score integer      not null default 0,
    player_two_score integer      not null default 0,
    winner_id        uuid         references public.profiles(id),
    round_duration   integer      not null default 120,   -- seconds
    target_score     integer,
    target_word_count integer,
    created_at       timestamptz  not null default now(),
    updated_at       timestamptz  not null default now()
);

create trigger matches_updated_at
    before update on public.matches
    for each row execute function public.handle_updated_at();

-- ──────────────────────────────────────────
-- Submitted Words
-- ──────────────────────────────────────────
create table if not exists public.submitted_words (
    id           uuid         primary key default uuid_generate_v4(),
    match_id     uuid         not null references public.matches(id) on delete cascade,
    player_id    uuid         not null references public.profiles(id),
    word         text         not null,
    points       integer      not null,
    submitted_at timestamptz  not null default now(),
    -- Prevent a player submitting the same word twice in a match
    unique (match_id, player_id, word)
);

-- ──────────────────────────────────────────
-- Friend Invites
-- ──────────────────────────────────────────
create table if not exists public.friend_invites (
    id             uuid         primary key default uuid_generate_v4(),
    from_player_id uuid         not null references public.profiles(id),
    to_player_id   uuid         not null references public.profiles(id),
    match_id       uuid         references public.matches(id),
    status         text         not null default 'pending'
                                check (status in ('pending','accepted','declined','expired')),
    created_at     timestamptz  not null default now(),
    check (from_player_id <> to_player_id)
);

-- ──────────────────────────────────────────
-- Leaderboard (materialised view, refreshed periodically)
-- ──────────────────────────────────────────
create or replace view public.leaderboard as
    select
        id,
        username,
        avatar_url,
        wins,
        losses,
        total_words_found,
        case when (wins + losses) > 0
             then round(wins::numeric / (wins + losses) * 100, 1)
             else 0
        end as win_rate_pct
    from public.profiles
    order by wins desc, total_words_found desc;

-- ──────────────────────────────────────────
-- Row Level Security
-- ──────────────────────────────────────────

-- Profiles
alter table public.profiles enable row level security;

create policy "Profiles are viewable by everyone"
    on public.profiles for select using (true);

create policy "Users can update their own profile"
    on public.profiles for update
    using (auth.uid() = id);

create policy "Users can insert their own profile"
    on public.profiles for insert
    with check (auth.uid() = id);

-- Matches
alter table public.matches enable row level security;

create policy "Matches are viewable by participants"
    on public.matches for select
    using (auth.uid() = player_one_id or auth.uid() = player_two_id);

create policy "Players can create matches"
    on public.matches for insert
    with check (auth.uid() = player_one_id);

create policy "Participants can update their match"
    on public.matches for update
    using (auth.uid() = player_one_id or auth.uid() = player_two_id);

-- Submitted Words
alter table public.submitted_words enable row level security;

create policy "Words viewable by match participants"
    on public.submitted_words for select
    using (
        exists (
            select 1 from public.matches m
            where m.id = match_id
              and (m.player_one_id = auth.uid() or m.player_two_id = auth.uid())
        )
    );

create policy "Players can insert their own words"
    on public.submitted_words for insert
    with check (auth.uid() = player_id);

-- Friend Invites
alter table public.friend_invites enable row level security;

create policy "Invites viewable by sender or recipient"
    on public.friend_invites for select
    using (auth.uid() = from_player_id or auth.uid() = to_player_id);

create policy "Players can send invites"
    on public.friend_invites for insert
    with check (auth.uid() = from_player_id);

create policy "Recipient can update invite status"
    on public.friend_invites for update
    using (auth.uid() = to_player_id);

-- ──────────────────────────────────────────
-- Realtime publications
-- Enable realtime on tables that need live sync.
-- Run this after creating tables.
-- ──────────────────────────────────────────
begin;
  -- Remove existing publication if re-running
  drop publication if exists supabase_realtime;

  create publication supabase_realtime
    for table public.matches, public.submitted_words, public.friend_invites;
commit;
