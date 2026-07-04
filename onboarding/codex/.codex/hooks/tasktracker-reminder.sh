#!/usr/bin/env bash
# Codex SessionStart hook (TT-157): print the tasktracker KB-first reminder. Codex adds a
# hook's stdout (plain text or JSON hookSpecificOutput.additionalContext) to the model's
# developer context. Plain text is the simplest and needs no jq.
set -euo pipefail

echo "tasktracker is this project's shared work + knowledge base. BEFORE you start: call the tasktracker MCP tool get_started to load your projects + recent decisions, then search(q) the KB for prior ADRs/notes - never re-derive what it already records. AS you work: capture non-obvious findings as notes. ON close: graduate the durable decision into an ADR, then set the issue done."
