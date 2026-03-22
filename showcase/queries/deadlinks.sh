#!/usr/bin/env bash

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/wiki"
TMP_JSON="$(mktemp)"
trap 'rm -f "$TMP_JSON"' EXIT

bin/vimwiki-query scan --root "$ROOT" --format ndjson > "$TMP_JSON"

python3 - "$TMP_JSON" <<'PY'
from __future__ import annotations

import json
import sys
from collections import defaultdict

source_path = sys.argv[1]
with open(source_path, "r", encoding="utf-8") as handle:
    records = [json.loads(line) for line in handle if line.strip()]

headings_by_page: dict[str, list[dict]] = defaultdict(list)
for record in records:
    if record["type"] == "heading":
        headings_by_page[record["rel_path"]].append(record)


def section_for(link: dict) -> str | None:
    headings = headings_by_page.get(link["rel_path"], [])
    current = None
    for heading in headings:
        if int(heading["line"]) <= int(link["line"]):
            current = heading["text"]
        else:
            break
    return current


links = []
for record in records:
    if record["type"] != "link" or record.get("resolved", False):
        continue
    if record.get("is_external", False):
        continue
    if record.get("target", "").startswith("/people/") or record.get("target", "").startswith("/diary/"):
        continue
    if section_for(record) in {"Contents", "Backlinks"}:
        continue
    links.append(record)

by_source: dict[str, list[dict]] = defaultdict(list)
for link in links:
    by_source[link["rel_path"]].append(link)

print("# Deadlinks")
print()

if not by_source:
    print("No deadlinks found.")
    raise SystemExit(0)

for source in sorted(by_source):
    print(f"## [[/{source.removesuffix('.md')}]]")
    for link in sorted(by_source[source], key=lambda item: (int(item["line"]), item.get("text", ""))):
        print(f"- Line {link['line']}: {link['text']}")
    print()
PY
