#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/_common.sh"

TMP_JSON="$(mktemp)"
trap 'rm -f "$TMP_JSON"' EXIT

"$VIMWIKI_QUERY_BIN" scan --root "$ROOT" --format json > "$TMP_JSON"

python3 - "$TMP_JSON" <<'PY'
from __future__ import annotations

import re
import sys

from _lib import load_records, rel_to_link

records = load_records(sys.argv[1])
phrases = {
    "today": re.compile(r"\btoday\b", re.IGNORECASE),
    "this week": re.compile(r"\bthis week\b", re.IGNORECASE),
    "this month": re.compile(r"\bthis month\b", re.IGNORECASE),
    "this year": re.compile(r"\bthis year\b", re.IGNORECASE),
}

matches: dict[str, list[str]] = {key: [] for key in phrases}
for task in [record for record in records if record.get("type") == "task"]:
    text = task["text"]
    for label, pattern in phrases.items():
        if pattern.search(text):
            matches[label].append(f"{rel_to_link(task['page']['rel_path'])} {text}")

print("# Timeframe Tasks")
print()
for label in ["today", "this week", "this month", "this year"]:
    print(f"## {label.title()}")
    rows = matches[label]
    if rows:
        for row in rows:
            print(f"- {row}")
    else:
        print(f"- No tasks mentioning {label}.")
    print()
PY
