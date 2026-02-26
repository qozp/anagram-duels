# Anagram Duels – Setup Guide

## Prerequisites
- Xcode 15+
- iOS 17+ deployment target
- A Supabase account (free tier works)

---

## 1. Create Xcode Project

1. Open Xcode → **File → New → Project**
2. Choose **App** (iOS, SwiftUI, Swift)
3. Product name: `AnagramDuels`
4. Bundle ID: `com.yourname.AnagramDuels`
5. Save in the `AnagramDuels/` folder cloned from this repo

---

## 2. Add Swift Package: Supabase

1. Xcode → **File → Add Package Dependencies**
2. URL: `https://github.com/supabase/supabase-swift`
3. Version: Up to Next Major from `2.0.0`
4. Add product: **Supabase**

---

## 3. Add Source Files

Copy all files from the scaffold into your Xcode project:
- Drag the `AnagramDuels/` source folder into Xcode
- Ensure **"Copy items if needed"** is checked
- All `.swift` files must be added to the **AnagramDuels** target

---

## 4. Add words.txt

1. Obtain a word list file (one word per line, ~200k words)
2. Rename to `words.txt`
3. Drag into Xcode under `Resources/`
4. Ensure it's added to the **AnagramDuels** target (check the box)

---

## 5. Configure Supabase

### 5a. Run the Database Schema

1. Open your Supabase project → **SQL Editor**
2. Paste and run `Database/schema.sql`

### 5b. Enable Apple Sign-In

1. Supabase Dashboard → **Authentication → Providers**
2. Enable **Apple**
3. Follow the Apple Developer setup: create a Service ID, Key, and configure the callback URL

### 5c. Set Up xcconfig (Local Secrets)

1. Copy the template:
   ```bash
   cp AnagramDuels/Config/Development.xcconfig.example AnagramDuels/Config/Development.xcconfig
   ```
2. Open `Development.xcconfig` and fill in your values:
   ```
   SUPABASE_URL = https://your-project-id.supabase.co
   SUPABASE_ANON_KEY = your-anon-key-here
   ```
3. In Xcode: select the **project** (not a target) → **Info** tab
4. Under **Configurations**, set **Debug** to `Development`

### 5d. Expose Keys in Info.plist

Add these two entries to your `Info.plist`:
```xml
<key>SUPABASE_URL</key>
<string>$(SUPABASE_URL)</string>
<key>SUPABASE_ANON_KEY</key>
<string>$(SUPABASE_ANON_KEY)</string>
```

---

## 6. Enable Capabilities

In Xcode → Target → **Signing & Capabilities**:
- Add **Sign In with Apple**
- Add **Push Notifications**
- Add **Remote Notifications** (under Background Modes)

---

## 7. Seed Daily Challenges

```bash
pip install supabase
python Scripts/seed_daily_challenges.py \
  --url https://your-project.supabase.co \
  --key YOUR_SERVICE_ROLE_KEY \
  --words-file AnagramDuels/Resources/words.txt \
  --start-date 2025-01-01 \
  --days 730
```

> ⚠️ Use your **service role** key (not anon) for the seed script. Never put it in the app.

---

## 8. Set Up Auto-Cancel CRON (Optional for MVP)

In Supabase → **Edge Functions**, create a scheduled function that calls:
```sql
SELECT cancel_stale_matches(7);
```
Schedule it to run daily.

---

## 9. Build & Run

Select an iPhone 17 simulator or device and press **Run (⌘R)**.

---

## Continuing Development with Claude

To get full context in a new Claude conversation:
1. Use **Claude Projects** (claude.ai) — upload `CLAUDE.md` and key source files
2. Or paste the contents of `CLAUDE.md` at the start of a new chat

Key files to always share with Claude when asking for changes:
- `CLAUDE.md` — architecture overview
- The specific file(s) you want changed
- `AppConfig.swift` if changing game rules
