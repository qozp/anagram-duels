-- ============================================================
-- Anagram Duels – Supabase Database Schema
-- Run this in the Supabase SQL Editor for your project.
-- ============================================================

-- ============================================================
-- 1️⃣  USERS
-- ============================================================
CREATE TABLE users (
    id                    UUID PRIMARY KEY,              -- matches auth.users.id
    username              TEXT UNIQUE NOT NULL,
    apple_id              TEXT,                          -- Apple sub claim (nullable for guests)
    guest_flag            BOOLEAN NOT NULL DEFAULT TRUE,
    theme_mode            TEXT NOT NULL DEFAULT 'system'
                              CHECK (theme_mode IN ('system', 'light', 'dark')),
    notifications_enabled BOOLEAN NOT NULL DEFAULT TRUE,
    push_token            TEXT,
    cosmetic_config       JSONB,
    created_at            TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at            TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- Users can read/update only their own row
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "users_select_own"
    ON users FOR SELECT
    USING (auth.uid() = id);

CREATE POLICY "users_insert_own"
    ON users FOR INSERT
    WITH CHECK (auth.uid() = id);

CREATE POLICY "users_update_own"
    ON users FOR UPDATE
    USING (auth.uid() = id);

-- Usernames are publicly searchable (for invites)
CREATE POLICY "users_select_username_public"
    ON users FOR SELECT
    USING (TRUE);   -- read-only for other users; no sensitive fields exposed via app queries

-- ============================================================
-- 2️⃣  FRIENDS
-- ============================================================
CREATE TABLE friends (
    user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    friend_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    status     TEXT NOT NULL DEFAULT 'pending'
                   CHECK (status IN ('pending', 'accepted', 'blocked')),
    created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    PRIMARY KEY (user_id, friend_id),
    CHECK (user_id <> friend_id)
);

ALTER TABLE friends ENABLE ROW LEVEL SECURITY;

CREATE POLICY "friends_select_own"
    ON friends FOR SELECT
    USING (auth.uid() = user_id OR auth.uid() = friend_id);

CREATE POLICY "friends_insert_own"
    ON friends FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "friends_update_own"
    ON friends FOR UPDATE
    USING (auth.uid() = user_id OR auth.uid() = friend_id);

-- ============================================================
-- 3️⃣  MATCHES
-- ============================================================
CREATE TABLE matches (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    seed_word           CHAR(6) NOT NULL,
    status              TEXT NOT NULL DEFAULT 'pending'
                            CHECK (status IN ('pending', 'in_progress', 'completed', 'canceled')),
    invite_sender_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    invite_receiver_id  UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ NOT NULL DEFAULT now(),
    completed_at        TIMESTAMPTZ,
    canceled_at         TIMESTAMPTZ,
    CHECK (invite_sender_id <> invite_receiver_id)
);

ALTER TABLE matches ENABLE ROW LEVEL SECURITY;

-- Both participants can read a match
CREATE POLICY "matches_select_participants"
    ON matches FOR SELECT
    USING (auth.uid() = invite_sender_id OR auth.uid() = invite_receiver_id);

-- Only sender can create
CREATE POLICY "matches_insert_sender"
    ON matches FOR INSERT
    WITH CHECK (auth.uid() = invite_sender_id);

-- Both participants can update (to mark in_progress / completed)
CREATE POLICY "matches_update_participants"
    ON matches FOR UPDATE
    USING (auth.uid() = invite_sender_id OR auth.uid() = invite_receiver_id);

-- ============================================================
-- 4️⃣  MATCH SUBMISSIONS
-- ============================================================
CREATE TABLE match_submissions (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    match_id     UUID NOT NULL REFERENCES matches(id) ON DELETE CASCADE,
    user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    words        JSONB NOT NULL,        -- [{ word: string, points: int }]
    total_score  INT NOT NULL CHECK (total_score >= 0),
    submitted_at TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (match_id, user_id)          -- one submission per player per match
);

ALTER TABLE match_submissions ENABLE ROW LEVEL SECURITY;

-- Participants can read all submissions for their match
CREATE POLICY "submissions_select_participants"
    ON match_submissions FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM matches m
            WHERE m.id = match_id
              AND (m.invite_sender_id = auth.uid() OR m.invite_receiver_id = auth.uid())
        )
    );

-- Players can only insert their own submission
CREATE POLICY "submissions_insert_own"
    ON match_submissions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- ============================================================
-- 5️⃣  LEVELS
-- ============================================================
CREATE TABLE levels (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    level_number     INT NOT NULL UNIQUE CHECK (level_number > 0),
    seed_word        CHAR(6) NOT NULL,
    max_score        INT NOT NULL CHECK (max_score >= 0),
    star_thresholds  JSONB NOT NULL,    -- { "1": 0.30, "2": 0.60, "3": 0.85 }
    theme_name       TEXT,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE levels ENABLE ROW LEVEL SECURITY;

-- Levels are globally readable
CREATE POLICY "levels_select_all"
    ON levels FOR SELECT
    USING (TRUE);

-- ============================================================
-- 6️⃣  DAILY CHALLENGES
-- ============================================================
CREATE TABLE daily_challenges (
    id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    challenge_date DATE NOT NULL UNIQUE,
    seed_word      CHAR(6) NOT NULL,
    max_score      INT NOT NULL CHECK (max_score >= 0),
    created_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

ALTER TABLE daily_challenges ENABLE ROW LEVEL SECURITY;

-- Globally readable
CREATE POLICY "daily_challenges_select_all"
    ON daily_challenges FOR SELECT
    USING (TRUE);

-- ============================================================
-- 7️⃣  DAILY CHALLENGE SUBMISSIONS
-- ============================================================
CREATE TABLE daily_challenge_submissions (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    daily_challenge_id  UUID NOT NULL REFERENCES daily_challenges(id) ON DELETE CASCADE,
    user_id             UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    words               JSONB NOT NULL,     -- [{ word: string, points: int }]
    total_score         INT NOT NULL CHECK (total_score >= 0),
    submitted_at        TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (daily_challenge_id, user_id)    -- only first attempt counts
);

ALTER TABLE daily_challenge_submissions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "daily_submissions_select_all"
    ON daily_challenge_submissions FOR SELECT
    USING (TRUE);    -- leaderboard is public

CREATE POLICY "daily_submissions_insert_own"
    ON daily_challenge_submissions FOR INSERT
    WITH CHECK (auth.uid() = user_id);

-- ============================================================
-- 8️⃣  STATS
-- ============================================================
CREATE TABLE stats (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    friend_id       UUID REFERENCES users(id),   -- NULL = global/total stats
    match_type      TEXT NOT NULL CHECK (match_type IN ('multiplayer', 'daily', 'level')),
    total_games     INT NOT NULL DEFAULT 0 CHECK (total_games >= 0),
    wins            INT NOT NULL DEFAULT 0 CHECK (wins >= 0),
    current_streak  INT NOT NULL DEFAULT 0 CHECK (current_streak >= 0),
    longest_streak  INT NOT NULL DEFAULT 0 CHECK (longest_streak >= 0),
    last_updated    TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (user_id, friend_id, match_type)
);

ALTER TABLE stats ENABLE ROW LEVEL SECURITY;

CREATE POLICY "stats_select_own"
    ON stats FOR SELECT
    USING (auth.uid() = user_id);

CREATE POLICY "stats_insert_own"
    ON stats FOR INSERT
    WITH CHECK (auth.uid() = user_id);

CREATE POLICY "stats_update_own"
    ON stats FOR UPDATE
    USING (auth.uid() = user_id);

-- ============================================================
-- INDEXES
-- ============================================================
CREATE INDEX idx_matches_sender     ON matches(invite_sender_id);
CREATE INDEX idx_matches_receiver   ON matches(invite_receiver_id);
CREATE INDEX idx_matches_status     ON matches(status);
CREATE INDEX idx_matches_created    ON matches(created_at DESC);
CREATE INDEX idx_submissions_match  ON match_submissions(match_id);
CREATE INDEX idx_submissions_user   ON match_submissions(user_id);
CREATE INDEX idx_daily_subs_user    ON daily_challenge_submissions(user_id);
CREATE INDEX idx_daily_subs_score   ON daily_challenge_submissions(daily_challenge_id, total_score DESC);
CREATE INDEX idx_friends_user       ON friends(user_id);
CREATE INDEX idx_friends_status     ON friends(user_id, status);
CREATE INDEX idx_stats_user         ON stats(user_id);
CREATE INDEX idx_daily_date         ON daily_challenges(challenge_date);

-- ============================================================
-- AUTO-CANCEL FUNCTION (called by Edge Function CRON)
-- ============================================================
CREATE OR REPLACE FUNCTION cancel_stale_matches(max_age_days INT DEFAULT 7)
RETURNS INT AS $$
DECLARE
    affected INT;
BEGIN
    UPDATE matches
    SET
        status      = 'canceled',
        canceled_at = now(),
        updated_at  = now()
    WHERE
        status IN ('pending', 'in_progress')
        AND created_at < now() - (max_age_days || ' days')::INTERVAL;

    GET DIAGNOSTICS affected = ROW_COUNT;
    RETURN affected;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- UPDATED_AT TRIGGER
-- ============================================================
CREATE OR REPLACE FUNCTION set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_matches_updated_at
    BEFORE UPDATE ON matches
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_levels_updated_at
    BEFORE UPDATE ON levels
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_friends_updated_at
    BEFORE UPDATE ON friends
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
