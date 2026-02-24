# Build out an MVP

Anagram Duels - a word game centered around building anagrams from 6 random letters within one minute, with multiplayer and singleplayer game modes. 

# Anagram Duels — Tech Stack

SwiftUi - Frontend

Supabase - backend

Dictionary and valid starting letters stored locally on the app

# Core Gameplay Requirements

## Round Initialization

- Each round uses a random 6-letter base word from the dictionary. Levels will use a preset word.
- Letters are shuffled and displayed identically to both players.
- Rounds can support configurable modes:
    - Time-based (default)
    - Target score
    - Target word count

Gameplay

- Players may use any subset of the 6 letters.
- Letters may only be used once per submitted word.
- Words must:
    - Exist in the dictionary
    - Not have been previously submitted by that player
- visual feedback (valid/invalid/duplicate).
- Scoring:

Word Length: Score

2: 100
3: 300
4: 500
5: 1000
6: 2000

Additional requirements:

- End-of-game breakdown:
    - Player 1 words
    - Overlapping words
    - Player 2 words

Scoring values must be configurable (no hardcoding).

---

# User Interface Requirements

## Main Menu with tabs

- Levels
- Duels
- Daily Challenge
- Profile/Statistics/Settings

---

## 4.3 End Game Screen

- Final scores
- Winner indicator
- Word comparison breakdown
- Rematch
- Return to menu

---

# Data Storage

- Words.txt dataset for validation
- User profile:
    - Wins
    - Losses
    - Win rate
    - Total words found
- Match history
- Leaderboard data

---

# Social Features

(MVP subset prioritized)

### MVP:

- Friend invite system
- Friend rematch
- Share Functionality
- Notifications

---

# Development Guidelines

- No magic numbers, make things as configurable as possible with variables and constants
- Intuitive, low-friction interfaces
- Secure, correct, scalable, reliable, and maintainable code
- Does not need to have automated tests for now