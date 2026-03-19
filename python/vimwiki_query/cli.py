from __future__ import annotations

import argparse
import json
import sys

from vimwiki_query.scanner import scan_wiki


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
            records = scan_wiki(args.root)

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
