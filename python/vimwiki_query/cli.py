from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

from vimwiki_query.discovery import discover_markdown_files
from vimwiki_query.parser import parse_markdown_file


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(prog="vimwiki-query")
    subparsers = parser.add_subparsers(dest="command", required=True)

    scan_parser = subparsers.add_parser("scan")
    scan_parser.add_argument("--root", required=True)
    scan_parser.add_argument("--format", choices=("ndjson", "json"), required=True)

    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    try:
        if args.command == "scan":
            records = []
            root = Path(args.root)
            for rel_path in discover_markdown_files(root):
                records.extend(parse_markdown_file(root, rel_path))

            if args.format == "ndjson":
                for record in records:
                    print(json.dumps(record))
                return 0

            grouped = {"pages": [], "tasks": [], "headings": [], "links": []}
            for record in records:
                grouped[f"{record['type']}s"].append(record)

            print(json.dumps(grouped))
            return 0
    except ValueError as exc:
        print(str(exc), file=sys.stderr)
        return 1

    return 1


if __name__ == "__main__":
    raise SystemExit(main())
