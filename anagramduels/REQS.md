# Anagram Duels — Tech Stack

SwiftUi - Frontend

Supabase - backend

Dictionary and valid starting letters stored locally on the app (going to use the scrabble dictionary that I can find and upload)

# Anagram Duels — Product Requirements

## 1. Game Overview

**Anagram Duels** is a real-time 1v1 multiplayer anagram game where two players compete to create valid words from a shared set of six letters derived from a valid six-letter base word.

---

# 2. Core Gameplay Requirements

## 2.1 Round Initialization

- Each round uses a valid 6-letter base word from the dictionary.
- Letters are shuffled and displayed identically to both players.
- Rounds can support configurable modes:
    - Time-based (default)
    - Target score
    - Target word count

---

## 2.2 Word Rules

- Players may use any subset of the 6 letters.
- Letters may only be used once per submitted word.
- Words must:
    - Exist in the dictionary
    - Not have been previously submitted by that player
- Real-time validation required.
- Immediate visual feedback (valid/invalid/duplicate).

---

## 2.3 Multiplayer Mechanics

- 1v1 matches only.
- Friend-invite system (MVP priority).
- Optional quick match (future).
- Real-time synchronization of:
    - Submitted words
    - Scores
    - Timer
- Rematch functionality.
- End match if disconnected

---

# 3. Scoring System

Points awarded based on word length:

| Length | Points |
| --- | --- |
| 2 | 100 |
| 3 | 200 |
| 4 | 400 |
| 5 | 800 |
| 6 | 1600 |

Additional requirements:

- No duplicate scoring.
- Tie handling logic required.
- End-of-game breakdown:
    - Player 1 words
    - Overlapping words
    - Player 2 words

Scoring values must be configurable (no hardcoding).

---

# 4. User Interface Requirements

## 4.1 Main Menu

- Play (Quick Match — future)
- Challenge Friend (MVP)
- Profile / Stats
- Leaderboard
- Settings

---

## 4.2 Game Screen

- Prominent 6-letter display
- Word input
- Submit action
- Player score displays (both players visible)
- Round timer
- Scrollable submitted words list
- Real-time opponent activity indicator
- Optional: Emoji reactions (future)

---

## 4.3 End Game Screen

- Final scores
- Winner indicator
- Word comparison breakdown
- Rematch
- Return to menu

---

---

# 6. Data Storage Requirements

- Dictionary dataset for validation
- User profile:
    - Wins
    - Losses
    - Win rate
    - Total words found
- Match history
- Leaderboard data

---

# 7. Social Features

(MVP subset prioritized)

### MVP:

- Friend invite system
- Friend rematch
- Share Functionality
- Notifications

---

# 8. Accessibility Requirements

- VoiceOver support
- Dynamic Type compatibility
- Colorblind-safe palette
- Haptic feedback toggle

---

# 9. Additional Features (Post-MVP)

- Daily challenge mode
- Tutorial onboarding
- Word definitions on tap
- Advanced statistics

---

# 10. Non-Functional Requirements

- Configurable constants (no magic numbers or hardcoding)
- Scalable multiplayer architecture
- Secure backend validation

---

# Development Guidelines

- No magic numbers, make things as configurable as possible with variables and constants
- Intuitive, low-friction interfaces
- Secure, correct, scalable, reliable, and maintainable code
- Does not need to have automated tests for now
