# Codex CLI hook pack

Copy the `.codex/` folder into the root of the repo your Codex agent works in, then make
the script executable:

```
chmod +x .codex/hooks/tasktracker-reminder.sh
```

- The `[[hooks.SessionStart]]` table in `.codex/config.toml` runs
  `tasktracker-reminder.sh` at session start (and resume). The script prints the reminder
  to stdout, which Codex adds to the model's developer context.

Merge the tables into an existing `.codex/config.toml` if you already have one. Codex
ignores some security-sensitive keys in repo-local config, but `hooks` are honored; run
`/hooks` in the TUI to confirm the hook is loaded.
