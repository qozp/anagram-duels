# Anagram Duels — Setup Guide

## Prerequisites

| Tool | Version |
|------|---------|
| Xcode | 16+ |
| iOS Deployment Target | 18.0 |
| Supabase Account | Any plan |

---

## 1. Create the Xcode Project

1. Open **Xcode → File → New → Project**
2. Choose **iOS → App**
3. Fill in:
   - **Product Name:** `AnagramDuels`
   - **Bundle Identifier:** `com.stewgames.anagramduels`
   - **Interface:** SwiftUI
   - **Language:** Swift
   - **Minimum Deployments:** iOS 18.0
4. Save the project to this repo root so the folder becomes `AnagramDuels/AnagramDuels.xcodeproj`

---

## 2. Add Source Files

Drag every `.swift` file from `AnagramDuels/` into the Xcode project navigator.  
Make sure **"Add to target: AnagramDuels"** is checked for each file.

Also add:
- `Resources/Assets.xcassets` (replace Xcode's default)
- `Resources/dictionary.txt` ← **must be added to the target**

---

## 3. Add the Supabase Swift SDK via SPM

1. **Xcode → File → Add Package Dependencies...**
2. Enter URL: `https://github.com/supabase/supabase-swift`
3. Set **Dependency Rule:** Up to Next Major, `2.0.0`
4. Add product **`Supabase`** to the `AnagramDuels` target

---

## 4. Configure Supabase Credentials

Open `Config/SupabaseConfig.swift` and replace the two placeholders:

```swift
static let projectURL = URL(string: "https://YOUR_PROJECT_REF.supabase.co")!
static let anonKey    = "YOUR_SUPABASE_ANON_KEY"
```

Find these in your Supabase dashboard → **Project Settings → API**.

> ⚠️ Add `SupabaseConfig.swift` to `.gitignore` if your repo is public,  
> or move credentials to a `Secrets.xcconfig` file excluded from source control.

---

## 5. Run the Supabase Schema

1. Open your Supabase project → **SQL Editor**
2. Paste and run the contents of `supabase/schema.sql`
3. This creates all tables, RLS policies, and enables Realtime.

---

## 6. Configure Sign in with Apple

1. In Xcode, select the **AnagramDuels** target → **Signing & Capabilities**
2. Click **+ Capability** → add **Sign In with Apple**
3. In your Supabase dashboard → **Authentication → Providers → Apple**:
   - Enable the provider
   - Enter your **Services ID** and **Private Key** from Apple Developer portal
   - See [Supabase Apple Auth docs](https://supabase.com/docs/guides/auth/social-login/auth-apple)

---

## 7. Add Your Dictionary

1. Obtain a Scrabble word list (e.g. TWL06 or Collins CSW)
2. Format: one lowercase word per line, plain `.txt`
3. Replace `Resources/dictionary.txt` with your file
4. Ensure it is added to the **AnagramDuels target** in Xcode

---

## 8. Asset Catalog — Colours

The colour assets in `Resources/Assets.xcassets` use a **colorblind-safe palette** 
(blue-based primary, orange-red for errors, no pure red/green).

Both light and dark mode variants are defined. If you want to tweak colours,  
edit the `.colorset/Contents.json` files — **do not** use hex literals in Swift code.

---

## Project Structure

```
AnagramDuels/
├── AnagramDuelsApp.swift          # @main entry point
├── Config/
│   ├── AppConfig.swift            # ← All constants, scoring, timers (no magic numbers)
│   └── SupabaseConfig.swift       # ← Credentials (replace placeholders)
├── Core/
│   ├── SupabaseService.swift      # Shared Supabase client singleton
│   ├── Navigation/
│   │   ├── AppRouter.swift        # NavigationPath-based router
│   │   └── RootView.swift         # Auth gate → Main app
│   └── Extensions/
│       └── Extensions.swift       # Color helpers, View modifiers, String utils
├── Models/
│   └── Models.swift               # AppUser, Match, SubmittedWord, FriendInvite
├── Services/
│   ├── AuthService.swift          # Email + Sign in with Apple auth
│   └── DictionaryService.swift    # Bundle word list loader
├── Features/
│   ├── Auth/
│   │   └── AuthView.swift         # Sign In / Sign Up / Apple
│   ├── MainMenu/
│   │   ├── MainMenuView.swift     # ← Fully implemented
│   │   └── MainMenuViewModel.swift
│   └── Placeholders.swift         # GameView, ProfileView, LevelsView, etc.
└── Resources/
    ├── Assets.xcassets/           # Colorblind-safe color sets (light + dark)
    └── dictionary.txt             # Replace with real Scrabble word list

supabase/
└── schema.sql                     # Full DB schema, RLS, Realtime config

README.md                          # This file
```

---

## Configuring Game Constants

All game rules live in `Config/AppConfig.swift`. Change them there only:

```swift
AppConfig.Game.letterCount          // 6
AppConfig.Game.defaultRoundDuration // 120s
AppConfig.Game.scoringTable         // [1:100, 2:200, 3:300, 4:500, 5:800, 6:1300]
AppConfig.UI.cornerRadius           // 14
// ... etc
```

---

## Next Steps (implementation order suggestion)

1. `ChallengeFriendView` — friend search + invite via `friend_invites` table
2. `GameView` — letter display, word input, real-time score sync via Supabase Realtime
3. `ProfileView` — fetch stats from `profiles` table
4. `SettingsView` — haptics toggle, colorblind mode selector
5. `LevelsView` — preset word list with target scores
6. End game screen with word breakdown
7. Notifications (APNs + Supabase webhooks)
