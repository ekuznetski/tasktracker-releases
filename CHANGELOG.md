# Changelog

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

