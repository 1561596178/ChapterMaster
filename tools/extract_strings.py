#!/usr/bin/env python3
"""Chapter Master string extraction tool.

Scans .gml sources (scripts/, objects/) and the game data json files
(datafiles/data, datafiles/main) for human-readable string literals and
maintains the translation table datafiles/main/localization/zh-CN.json.

Usage:
    python tools/extract_strings.py            # gml + json data
    python tools/extract_strings.py --gml-only # only gml sources

Existing translations in zh-CN.json are always preserved; new keys are
added with the source English string as a fallback value.
"""

import argparse
import json
import os
import re

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
LOC_FILE = os.path.join(ROOT, "datafiles", "main", "localization", "zh-CN.json")
SRC_FOLDERS = [os.path.join(ROOT, "scripts"), os.path.join(ROOT, "objects")]
DATA_FOLDERS = [
    os.path.join(ROOT, "datafiles", "data"),
    os.path.join(ROOT, "datafiles", "main"),
]

STRING_RE = re.compile(r'"((?:\\.|[^"\\])*)"')
JSON_VALUE_RE = re.compile(r'"[^"]*"\s*:\s*"((?:\\.|[^"\\])*)"')
JSON_KEY_RE = re.compile(r'"((?:\\.|[^"\\])*)"\s*:\s*\{')

SINGLE_WORD_RE = re.compile(r"^[A-Za-z][A-Za-z0-9_.]*$")
DIGIT_PUNCT_RE = re.compile(r"^[\d.,%:\s+-]+$")
HEX_COLOR_RE = re.compile(r"^#[0-9a-fA-F]{6}$")
UPPER_IDENT_RE = re.compile(r"^[A-Z_][A-Z0-9_]*$")
FILE_PATH_RE = re.compile(r"(?:^|[\\/])[\w.-]+\.(?:png|json|ini|txt|yy|gml|jpg|jpeg|wav|ogg|mp3|dat|ttf)(?:$|[\\/])", re.I)


def is_text_value(value):
    """Heuristic: is this string likely user-facing text?"""
    if not value or len(value) < 2:
        return False
    # Skip escaped-variant garbage keys: strings containing many backslashes
    # (the extractor's regex multiplies \\n escapes on re-scans).
    if value.count("\\") > 4:
        return False
    if "\n" in value:
        return True
    if DIGIT_PUNCT_RE.fullmatch(value):
        return False
    if HEX_COLOR_RE.fullmatch(value):
        return False
    if UPPER_IDENT_RE.fullmatch(value):
        return False
    if FILE_PATH_RE.search(value):
        return False
    if re.search(r"[A-Za-z\u4e00-\u9fff]", value):
        return True
    return False


def scan_gml_files(folders):
    found = []
    for folder in folders:
        for base, _dirs, files in os.walk(folder):
            for name in files:
                if not name.endswith(".gml"):
                    continue
                path = os.path.join(base, name)
                rel = os.path.relpath(path, ROOT)
                try:
                    with open(path, encoding="utf-8-sig", errors="replace") as fh:
                        content = fh.read()
                except OSError:
                    continue
                for line_no, line in enumerate(content.splitlines(), 1):
                    for m in STRING_RE.finditer(line):
                        value = m.group(1)
                        if is_text_value(value):
                            found.append((value, rel, line_no))
    return found


def scan_json_files(folders):
    found = []
    for folder in folders:
        for base, _dirs, files in os.walk(folder):
            for name in files:
                if not name.endswith(".json"):
                    continue
                path = os.path.join(base, name)
                rel = os.path.relpath(path, ROOT)
                try:
                    content = open(path, encoding="utf-8-sig").read()
                except (OSError, UnicodeDecodeError):
                    continue
                # value slots: "some key" : "text"
                for m in JSON_VALUE_RE.finditer(content):
                    value = m.group(1)
                    if is_text_value(value) and re.search(r"[a-zA-Z]{3}", value):
                        found.append((value, rel, 0))
                # dict KEYS that look like display names/IDs used as labels
                #   "Human-readable Key Name": { ... }
                for m in JSON_KEY_RE.finditer(content):
                    value = m.group(1)
                    # a key is only useful for translation if it has a following '{'
                    if is_text_value(value) and re.search(r"[a-zA-Z]{3}", value):
                        found.append((value, rel, 0))
    return found


def main():
    parser = argparse.ArgumentParser(description="Extract Localization strings from Chapter Master source.")
    parser.add_argument("--gml-only", action="store_true", help="skip the data json files")
    args = parser.parse_args()

    entries = scan_gml_files(SRC_FOLDERS)
    if not args.gml_only:
        entries += scan_json_files(DATA_FOLDERS)

    sources = {}
    for value, rel, line_no in entries:
        key = value
        if key not in sources:
            sources[key] = (rel, line_no)

    existing = {}
    if os.path.exists(LOC_FILE):
        try:
            with open(LOC_FILE, encoding="utf-8-sig") as fh:
                existing = json.load(fh)
        except Exception:
            existing = {}

    table = {}
    for key in sorted(sources):
        table[key] = existing.get(key) or key
    for key in sorted(existing):
        table.setdefault(key, existing.get(key) or key)

    os.makedirs(os.path.dirname(LOC_FILE), exist_ok=True)
    with open(LOC_FILE, "w", encoding="utf-8") as fh:
        json.dump(table, fh, ensure_ascii=False, indent=2)
        fh.write("\n")

    untranslated = sum(1 for k, v in table.items() if not v or v == k)
    print(f"Total keys: {len(table)} ({untranslated} untranslated, {len(table) - untranslated} translated)")
    print(f"Source files referenced: {len(set(rel for rel, _ in sources.values()))}")
    print(f"Written: {LOC_FILE}")


if __name__ == "__main__":
    main()