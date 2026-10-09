"""Build a small, committable sample of the source data in sample_data/.

Samples listing IDs across all months (not rows per month), so each sampled
listing keeps its full monthly history and the SCD2 snapshots still see changes.
Reference files (census, suburb) are small, so they are copied whole.

Usage: uv run python scripts/make_sample_data.py
"""
import csv
import random
import shutil
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SOURCE_DIR = ROOT / "data"
SAMPLE_DIR = ROOT / "sample_data"
SAMPLE_SIZE = 100
SEED = 42


def read_listing_ids(path):
    with open(path, encoding="utf-8", newline="") as f:
        return {row["LISTING_ID"] for row in csv.DictReader(f)}


def write_sample(source, target, listing_ids):
    with open(source, encoding="utf-8", newline="") as src, open(target, "w", encoding="utf-8", newline="") as dst:
        reader = csv.DictReader(src)
        writer = csv.DictWriter(dst, fieldnames=reader.fieldnames, lineterminator="\n")
        writer.writeheader()
        rows = [row for row in reader if row["LISTING_ID"] in listing_ids]
        writer.writerows(rows)

    return len(rows)


def main():
    listing_files = sorted((SOURCE_DIR / "listings").glob("*.csv"))
    all_ids = set().union(*(read_listing_ids(path) for path in listing_files))
    sampled_ids = set(random.Random(SEED).sample(sorted(all_ids), SAMPLE_SIZE))

    (SAMPLE_DIR / "listings").mkdir(parents=True, exist_ok=True)

    for path in listing_files:
        row_count = write_sample(path, SAMPLE_DIR / "listings" / path.name, sampled_ids)
        print(f"listings/{path.name}: {row_count} rows")

    for folder in ("census", "suburb"):
        shutil.copytree(SOURCE_DIR / folder, SAMPLE_DIR / folder, dirs_exist_ok=True)
        print(f"{folder}/: copied")


if __name__ == "__main__":
    main()
