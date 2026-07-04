# Connect your agent to tasktracker

tasktracker is your project's shared **work** (issues) and **durable knowledge** (notes /
ADRs). Agents get the most out of it when they start every session by reading the KB and
end it by capturing what they learned. Two layers make that happen:

1. **Universal (works everywhere, nothing to install).** The MCP server ships an
   `instructions` block that every connecting client folds into its system prompt, plus a
   periodic `get_started` / capture-a-note nudge on the results. This alone covers hookless
   clients such as Claude Desktop.
2. **Per-client hooks (recommended).** A tiny session-start hook injects the reminder into
   the agent's context the moment a session opens, so "call `get_started`, search the KB
   first" is impossible to miss. Packs for Claude Code, Cursor, and Codex are below.

All three packs inject the same reminder (see `AGENT_SESSION_REMINDER` in
`src/kb-guidance.ts`):

> tasktracker is this project's shared work + knowledge base. BEFORE you start: call the
> tasktracker MCP tool `get_started` to load your projects + recent decisions, then
> `search(q)` the KB for prior ADRs/notes - never re-derive what it already records. AS
> you work: capture non-obvious findings as notes. ON close: graduate the durable decision
> into an ADR, then set the issue done.

## First, connect the MCP server

Copy the connect command from the **Connect an agent** panel in the web UI (Access
control), e.g.:

```
claude mcp add --transport http --client-id tasktracker-cli --callback-port 8080 tasktracker https://YOUR-HOST/mcp
```

(In solo mode the server is unauthenticated, so the same command connects with no OAuth
step.)

## Then, wire the session-start hook

Copy the matching folder's files into the **root of the repo your agent works in**:

| Client       | Copy into your repo            | What fires it                       |
| ------------ | ------------------------------ | ----------------------------------- |
| Claude Code  | `claude-code/.claude/`         | `SessionStart` hook                 |
| Cursor       | `cursor/.cursor/`              | `sessionStart` hook                 |
| Codex CLI    | `codex/.codex/`                | `SessionStart` hook                 |

Each pack is a plain shell/JSON reminder - no dependencies. Edit the reminder text in the
hook if your team wants to say more. See each subfolder for details.

### Verify it fires

Open a fresh session in your client from that repo. You should see the reminder in the
agent's context at the top of the session; the agent then calls `get_started` before
working. For hookless clients (Claude Desktop), the same directive arrives via the MCP
`instructions` block - no hook needed.
