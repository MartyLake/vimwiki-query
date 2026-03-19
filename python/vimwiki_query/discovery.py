from __future__ import annotations

from pathlib import Path


def discover_markdown_files(root: Path | str) -> list[str]:
    root_path = Path(root)
    if not root_path.is_dir():
        raise ValueError(f"Root path does not exist or is not a directory: {root_path}")

    return sorted(str(path.relative_to(root_path)) for path in root_path.rglob("*.md"))
