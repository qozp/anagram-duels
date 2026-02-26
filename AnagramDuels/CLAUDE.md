# Anagram Duels – Project Context for Claude

## Project Overview
Anagram Duels is a SwiftUI word game where players build anagrams from 6 random letters within one minute.
Modes: Singleplayer (Levels + Practice), Multiplayer (async, friends only), Daily Challenge.

## Tech Stack
- **Frontend**: SwiftUI (iOS, minimum target TBD — recommend iOS 17+)
- **Backend**: Supabase (Auth, Database, Edge Functions, Push via APNs)
- **Package Manager**: Swift Package Manager (via Xcode)
- **SPM Dependency**: `https://github.com/supabase/supabase-swift` (import `Supabase`)

## Project Structure
```
AnagramDuels/
├── CLAUDE.md
├── AnagramDuels.xcodeproj
├── AnagramDuels/
│   ├── AnagramDuelsApp.swift          # App entry point, environment setup
│   ├── Config/
│   │   ├── AppConfig.swift            # All magic numbers / configurable constants
│   │   ├── SupabaseConfig.swift       # Reads URL + key from Info.plist / xcconfig
│   │   └── Development.xcconfig       # Gitignored — holds real Supabase keys
│   ├── Models/
│   │   ├── UserModel.swift
│   │   ├── MatchModel.swift
│   │   ├── LevelModel.swift
│   │   ├── DailyChallengeModel.swift
│   │   ├── FriendModel.swift
│   │   ├── StatsModel.swift
│   │   └── GameModels.swift           # LetterTile, ScoredWord, GamePhase, GameContext
│   ├── Services/
│   │   ├── SupabaseService.swift      # Singleton SupabaseClient wrapper
│   │   ├── AuthService.swift          # Apple Sign-In + guest login
│   │   ├── WordValidationService.swift # Loads words.txt into Set<String>
│   │   ├── GameScoringService.swift   # Pure scoring logic
│   │   └── NotificationService.swift  # APNs registration + local scheduling
│   ├── ViewModels/
│   │   ├── AuthViewModel.swift
│   │   ├── GameViewModel.swift        # Core game logic: tiles, timer, submission
│   │   ├── MultiplayerViewModel.swift
│   │   ├── SingleplayerViewModel.swift
│   │   ├── DailyViewModel.swift
│   │   └── ProfileViewModel.swift
│   ├── Views/
│   │   ├── Root/
│   │   │   ├── ContentView.swift      # Auth gate → MainTabView
│   │   │   └── MainTabView.swift      # 4-tab container
│   │   ├── Auth/
│   │   │   └── AuthView.swift         # Apple Sign-In + guest CTA
│   │   ├── Game/
│   │   │   ├── GameBoardView.swift    # Main game UI (tiles, timer, submit)
│   │   │   ├── LetterTileView.swift   # Individual tile component
│   │   │   └── ResultsView.swift      # Post-game results screen
│   │   ├── Multiplayer/
│   │   │   ├── MultiplayerInboxView.swift
│   │   │   ├── MatchDetailView.swift
│   │   │   └── InviteFriendView.swift
│   │   ├── Singleplayer/
│   │   │   ├── SingleplayerHomeView.swift
│   │   │   ├── LevelSelectView.swift
│   │   │   └── PracticeModeView.swift
│   │   ├── Daily/
│   │   │   ├── DailyView.swift
│   │   │   └── LeaderboardView.swift
│   │   └── Profile/
│   │       ├── ProfileView.swift
│   │       ├── FriendsView.swift
│   │       └── SettingsView.swift
│   ├── Extensions/
│   │   ├── Color+Theme.swift
│   │   └── View+Modifiers.swift
│   └── Resources/
│       └── words.txt                  # ~200k words, one per line, bundled in app
├── Database/
│   └── schema.sql                     # Full Supabase schema with RLS
└── Scripts/
    └── seed_daily_challenges.py       # Generates daily_challenges rows from words.txt
```

## Architecture Decisions

### Authentication
- **Multiplayer users**: Apple Sign-In → Supabase `signInWithIdToken`
- **Singleplayer users**: Guest login → anonymous Supabase user + local UUID fallback
- `AuthViewModel` drives the auth state machine; injected via `@EnvironmentObject`

### Word Validation
- `words.txt` bundled in app (not hidden; acceptable for MVP)
- Loaded **once** on app launch into `Set<String>` via `WordValidationService`
- Validation is O(1) lookup; happens **on submission**, not on keystroke
- All words must be: (a) in the set, (b) 2–6 letters, (c) constructable from seed letters, (d) not already submitted this round

### Game Engine
- `GameViewModel` is the single source of truth for all game state
- Initialized with a `GameContext` (practice/level/multiplayer/daily)
- Timer is a Swift `Task` counting down `AppConfig.gameDuration` seconds
- Hand has 6 `LetterTile`s; each has a fixed `handIndex` and `isPlaced` state
- Word slots are `[UUID?]` (6 slots); holds tile IDs
- Tapping a hand tile places it in the next empty slot
- Tapping a word tile returns it to its **original hand index**
- "Clear All" button returns all word tiles to hand
- Submitted words displayed only **after time expires**

### Scoring
- Defined in `AppConfig.wordScores: [Int: Int]` (keyed by word length)
- `GameScoringService.score(for:)` is a pure function
- Max score for levels/daily is precomputed by scoring all valid subwords of the seed

### Multiplayer
- Async play: each player plays independently
- Match states: `pending → in_progress → completed | canceled`
- Auto-cancel: Edge Function (CRON) runs daily, cancels matches older than `AppConfig.matchAutoCancelDays`
- Player inbox: all matches where they are sender or receiver
- Waiting state: after submission, player can view their submitted words but not replay

### Daily Challenge
- One word per day, globally consistent (`daily_challenges` table)
- Only first submission counted (`UNIQUE` constraint on `daily_challenge_id + user_id`)
- Leaderboard: friends + global, sorted by `total_score DESC, submitted_at ASC`
- Seeded in bulk via `Scripts/seed_daily_challenges.py`

### Notifications
- `NotificationService` handles APNs registration
- Token stored in `users.push_token` column
- Supabase Edge Function sends push on match submission (notifies opponent)

### Theme
- `AppConfig.ThemeMode`: `system | light | dark`
- Stored in `users.theme_mode`; applied via `.preferredColorScheme` at root
- `Color+Theme.swift` defines semantic colors (background, tile, accent, etc.)

## Configuration (No Magic Numbers)
All constants live in `AppConfig.swift`:
- `gameDuration: Int = 60`
- `wordScores: [Int: Int]`
- `starThresholds: [Int: Double]` — percentage of max score per star
- `matchAutoCancelDays: Int = 7`
- `minimumWordLength: Int = 2`
- `seedWordLength: Int = 6`
- `levelsPerGroup: Int = 10`

## Supabase Setup
1. Create project at supabase.com
2. Run `Database/schema.sql` in the SQL editor
3. Enable Apple provider in Auth settings
4. Add `SUPABASE_URL` and `SUPABASE_ANON_KEY` to `Development.xcconfig` (gitignored)
5. In Xcode: Project → Info → set xcconfig for Debug/Release

## Key Conventions
- All async Supabase calls use `async/await` with `try`
- ViewModels publish `errorMessage: String?` for UI error display
- Models use `snake_case` `CodingKeys` to match Supabase column names
- All DB timestamps are `Date`; decoded via `ISO8601DateFormatter`
- RLS is enabled on all tables; users can only read/write their own data

## Known Stubs / TODOs
- `levels` table is empty at launch; needs a content pipeline
- Suggested friends (stretch): not implemented
- Cosmetic customization (stretch): `cosmetic_config JSONB` column reserved
- Public matchmaking (stretch): not implemented

## Running the Seed Script
```bash
pip install supabase
python Scripts/seed_daily_challenges.py \
  --url https://xxxx.supabase.co \
  --key YOUR_SERVICE_ROLE_KEY \
  --words-file AnagramDuels/Resources/words.txt \
  --start-date 2025-01-01 \
  --days 730
```
