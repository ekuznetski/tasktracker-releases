# Changelog

## v0.1.22 - 2026-07-20

- docs: append DEPLOYER-FEEDBACK Part 3 (two-agent coordination pain points)
- TT-229: OAuth/MCP access diagnosability - identity + reason in logs (#86)

## v0.1.21 - 2026-07-15

- TT-228: lease must not evict active work (#85)

## v0.1.20 - 2026-07-14

- TT-225: loud lease expiry + wait_for_changes proxy hardening + coordination guide (#84)

## v0.1.19 - 2026-07-13

- TT-224: wait_for_changes long-poll MCP tool (#83)
- TT-223: stop Assignee autofill popover and truncate long property values (#82)
- TT-222: rank exact issue-number/key first in list_issues(q=) (#81)

## v0.1.18 - 2026-07-11

- TT-220: stretch every board column to the full scroll height (#80)
- design: update tasktracker.pen (#79)

## v0.1.17 - 2026-07-11

- TT-221: prompt on any real server sha ahead of the bundle, not just server-changed (#78)
- TT-221: land deployed frontend updates in the browser (#77)
- TT-220: extend board column highlight/drop-zone to full scroll height (#76)

## v0.1.16 - 2026-07-11

- TT-219: fuzzy search - typo and partial-word tolerance via index-vocabulary correction (#75)

## v0.1.15 - 2026-07-11

- TT-218: relax zero-hit multi-term search to OR-of-significant-terms (#74)
- TT-217: display-key issue refs on every MCP tool, list_issues number/sort/compact (#73)

## v0.1.14 - 2026-07-11

- TT-216: make search match issue number, display key and git branch
- TT-215: list all connectable MCP clients in the connect-agent dialog

## v0.1.13 - 2026-07-07

- TT-213: flush SSE headers immediately + X-Accel-Buffering so /events is stable behind a proxy
- TT-212: add /consent page so prompt=consent clients (Claude, ChatGPT) complete OAuth

## v0.1.12 - 2026-07-07

- TT-211: resume the OAuth authorize flow after sign-in so MCP connectors complete

## v0.1.11 - 2026-07-07

- TT-210: trust chatgpt.com connector-callback prefix so any user can connect ChatGPT (DCR stays off)

## v0.1.10 - 2026-07-07

- TT-209: derive Codex CLI's per-server OAuth callback in the seed so it connects out of the box

## v0.1.9 - 2026-07-07

- TT-208: whitelist mainstream MCP client OAuth callbacks (Claude Desktop/web, Cursor, VS Code, opencode/Cline/Kilo, Gemini, Goose)
- TT-207: constrain connect-agent dialog width so long commands scroll in their code box

## v0.1.8 - 2026-07-07

- TT-206: in-app Connect-an-agent MCP guide (account menu, per-instance URL, all clients)
- TT-205: prompt a reload when the served build changes

## v0.1.7 - 2026-07-07

- TT-204: check-for-updates button + auto CHANGELOG on release

