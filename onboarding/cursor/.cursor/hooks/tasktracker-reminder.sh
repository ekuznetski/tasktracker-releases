#!/usr/bin/env bash
# Cursor sessionStart hook (TT-157): inject the tasktracker KB-first reminder into the
# agent's context. Cursor reads the `additional_context` field from stdout JSON.
set -euo pipefail

cat <<'JSON'
{
  "additional_context": "tasktracker is this project's shared work + knowledge base. BEFORE you start: call the tasktracker MCP tool get_started to load your projects + recent decisions, then search(q) the KB for prior ADRs/notes - never re-derive what it already records. AS you work: capture non-obvious findings as notes. ON close: graduate the durable decision into an ADR, then set the issue done."
}
JSON
