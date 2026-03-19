from __future__ import annotations

import os
import subprocess
import sys
from pathlib import Path

import pytest


REPO_ROOT = Path(__file__).resolve().parents[1]
PYTHON_DIR = REPO_ROOT / "python"
BIN_PATH = REPO_ROOT / "bin" / "vimwiki-query"

if str(PYTHON_DIR) not in sys.path:
    sys.path.insert(0, str(PYTHON_DIR))


@pytest.fixture
def sample_wiki_root() -> Path:
    return REPO_ROOT / "tests" / "fixtures" / "wiki"


@pytest.fixture
def run_cli():
    def _run(*args: str) -> subprocess.CompletedProcess[str]:
        env = os.environ.copy()
        env["PYTHONPATH"] = str(PYTHON_DIR)
        return subprocess.run(
            [sys.executable, "-m", "vimwiki_query.cli", *args],
            cwd=REPO_ROOT,
            env=env,
            text=True,
            capture_output=True,
            check=False,
        )

    return _run


@pytest.fixture
def run_bin_cli():
    def _run(*args: str) -> subprocess.CompletedProcess[str]:
        return subprocess.run(
            [str(BIN_PATH), *args],
            cwd=REPO_ROOT,
            text=True,
            capture_output=True,
            check=False,
        )

    return _run
