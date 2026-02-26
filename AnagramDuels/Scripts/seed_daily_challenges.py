#!/usr/bin/env python3
"""
seed_daily_challenges.py
Generates and inserts daily challenge rows into Supabase.

Usage:
    pip install supabase
    python seed_daily_challenges.py \
        --url https://your-project.supabase.co \
        --key YOUR_SERVICE_ROLE_KEY \
        --words-file path/to/words.txt \
        --start-date 2025-01-01 \
        --days 730

The script:
  - Selects random 6-letter words WITHOUT replacement across all generated dates.
  - Skips dates that already have a challenge (safe to re-run).
  - Computes max_score for each word (sum of all sub-words' point values).
  - Inserts in batches of 50 to avoid request limits.
"""

import argparse
import random
import sys
from datetime import date, timedelta
from typing import Optional

# ---------------------------------------------------------------------------
# Scoring table — must match AppConfig.wordScores in Swift
# ---------------------------------------------------------------------------
WORD_SCORES: dict[int, int] = {
    2: 100,
    3: 300,
    4: 600,
    5: 1000,
    6: 1500,
}

MIN_WORD_LENGTH = 2
SEED_WORD_LENGTH = 6
BATCH_SIZE = 50


# ---------------------------------------------------------------------------
# Core helpers
# ---------------------------------------------------------------------------

def load_words(path: str) -> list[str]:
    """Returns all words from the file as lowercase stripped strings."""
    with open(path, "r", encoding="utf-8") as f:
        words = [line.strip().lower() for line in f if line.strip()]
    return words


def filter_seed_candidates(words: list[str]) -> list[str]:
    """Keep only exactly 6-letter alphabetic words suitable as seeds."""
    return [w for w in words if len(w) == SEED_WORD_LENGTH and w.isalpha()]


def letter_frequency(word: str) -> dict[str, int]:
    freq: dict[str, int] = {}
    for c in word:
        freq[c] = freq.get(c, 0) + 1
    return freq


def can_form(candidate: str, seed_freq: dict[str, int]) -> bool:
    """Returns True if candidate can be constructed from the seed's letters."""
    available = dict(seed_freq)
    for c in candidate:
        if available.get(c, 0) == 0:
            return False
        available[c] -= 1
    return True


def compute_max_score(seed_word: str, word_set: set[str]) -> int:
    """Sum of scores for every valid sub-word constructable from seed_word."""
    seed_freq = letter_frequency(seed_word)
    total = 0
    for word in word_set:
        length = len(word)
        if MIN_WORD_LENGTH <= length <= SEED_WORD_LENGTH:
            if can_form(word, seed_freq):
                total += WORD_SCORES.get(length, 0)
    return total


# ---------------------------------------------------------------------------
# Supabase interaction
# ---------------------------------------------------------------------------

def fetch_existing_dates(client) -> set[str]:
    """Returns the set of challenge_date strings already in the DB."""
    response = client.table("daily_challenges").select("challenge_date").execute()
    return {row["challenge_date"] for row in (response.data or [])}


def insert_batch(client, rows: list[dict]) -> None:
    client.table("daily_challenges").insert(rows).execute()


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(description="Seed daily_challenges table.")
    parser.add_argument("--url",        required=True, help="Supabase project URL")
    parser.add_argument("--key",        required=True, help="Supabase SERVICE ROLE key (not anon)")
    parser.add_argument("--words-file", required=True, help="Path to words.txt")
    parser.add_argument("--start-date", required=True, help="First challenge date (YYYY-MM-DD)")
    parser.add_argument("--days",       required=True, type=int, help="Number of days to generate")
    parser.add_argument("--seed",       type=int, default=None, help="Random seed for reproducibility")
    args = parser.parse_args()

    if args.seed is not None:
        random.seed(args.seed)

    # Import here so the script works without supabase if just checking --help
    try:
        from supabase import create_client
    except ImportError:
        print("ERROR: supabase-py not installed. Run: pip install supabase")
        sys.exit(1)

    print("Loading words…")
    all_words = load_words(args.words_file)
    word_set = set(all_words)
    candidates = filter_seed_candidates(all_words)
    print(f"  {len(all_words):,} total words | {len(candidates):,} 6-letter candidates")

    if len(candidates) < args.days:
        print(f"WARNING: Only {len(candidates)} candidates for {args.days} days — words will repeat.")

    client = create_client(args.url, args.key)

    print("Fetching existing challenge dates…")
    existing_dates = fetch_existing_dates(client)
    print(f"  {len(existing_dates)} dates already seeded.")

    # Build target date range
    try:
        start = date.fromisoformat(args.start_date)
    except ValueError:
        print(f"ERROR: Invalid start-date '{args.start_date}'. Use YYYY-MM-DD.")
        sys.exit(1)

    target_dates = [
        (start + timedelta(days=i)).isoformat()
        for i in range(args.days)
        if (start + timedelta(days=i)).isoformat() not in existing_dates
    ]

    if not target_dates:
        print("All target dates already seeded. Nothing to do.")
        return

    print(f"Generating {len(target_dates)} new challenges…")

    # Sample without replacement (cycle if needed)
    shuffled = candidates.copy()
    random.shuffle(shuffled)
    pool = []
    while len(pool) < len(target_dates):
        extra = candidates.copy()
        random.shuffle(extra)
        pool.extend(extra)
    selected_words = pool[:len(target_dates)]

    rows: list[dict] = []
    for i, (challenge_date_str, seed_word) in enumerate(zip(target_dates, selected_words)):
        max_score = compute_max_score(seed_word, word_set)
        rows.append({
            "challenge_date": challenge_date_str,
            "seed_word":      seed_word.upper(),
            "max_score":      max_score,
        })
        if (i + 1) % 50 == 0:
            print(f"  Computed {i + 1}/{len(target_dates)}…")

    # Insert in batches
    print(f"Inserting {len(rows)} rows in batches of {BATCH_SIZE}…")
    for i in range(0, len(rows), BATCH_SIZE):
        batch = rows[i : i + BATCH_SIZE]
        insert_batch(client, batch)
        print(f"  Inserted rows {i + 1}–{i + len(batch)}")

    print(f"\n✅  Done. Seeded {len(rows)} daily challenges.")


if __name__ == "__main__":
    main()
