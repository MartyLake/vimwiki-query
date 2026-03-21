#!/usr/bin/env bash

SHOWCASE_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
ROOT="${SHOWCASE_WIKI_ROOT:-${SHOWCASE_DIR}/wiki}"
VIMWIKI_QUERY_BIN="${VIMWIKI_QUERY_BIN:-${SHOWCASE_DIR}/../bin/vimwiki-query}"
