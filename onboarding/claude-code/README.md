# Claude Code hook pack

Copy `.claude/settings.json` into the root of the repo your Claude Code agent works in
(merge with any existing `.claude/settings.json`).

- **SessionStart** echoes the tasktracker reminder; Claude Code adds stdout to the
  session context, so the agent sees "call `get_started`, search the KB first" before it
  does anything.
- **Stop** echoes a gentle end-of-turn reminder to capture decisions as notes/ADRs. It is
  non-blocking - remove the `Stop` block if you find it noisy.

No dependencies (plain `echo`). Reload the window (or start a new session) after copying.
