"""Merge a hand-curated translation batch into zh-CN.json.

Usage:
    python tools/merge_translations.py tools/zh_batch_001.json

Only empty entries are filled; existing translations are never overwritten.
"""

import json
import sys
import os

BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
TARGET = os.path.join(BASE, "datafiles", "main", "localization", "zh-CN.json")


def main():
    if len(sys.argv) < 2:
        print("usage: python tools/merge_translations.py <batch.json> [<batch2.json> ...]")
        return 1
    table = json.load(open(TARGET, encoding="utf-8"))
    total_new = 0
    for batch_path in sys.argv[1:]:
        batch = json.load(open(batch_path, encoding="utf-8"))
        applied = 0
        missing = 0
        for k, v in batch.items():
            if k not in table:
                missing += 1
                print(f"  !! key not in table: {k!r}")
                continue
            if not table[k]:
                table[k] = v
                applied += 1
        print(f"{os.path.basename(batch_path)}: applied {applied}, skipped {len(batch) - applied}, unknown {missing}")
        total_new += applied
    with open(TARGET, "w", encoding="utf-8") as f:
        json.dump(table, f, ensure_ascii=False, indent=2)
    print(f"total new translations: {total_new}")


if __name__ == "__main__":
    sys.exit(main())