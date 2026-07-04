# Cursor hook pack

Copy the `.cursor/` folder into the root of the repo your Cursor agent works in (merge
with any existing `.cursor/hooks.json`), then make the script executable:

```
chmod +x .cursor/hooks/tasktracker-reminder.sh
```

- **sessionStart** runs `tasktracker-reminder.sh`, which prints JSON with an
  `additional_context` field. Cursor injects that text into the agent's context at session
  start (`additional_context` is the only documented way for a hook to add context).

Cursor's `beforeSubmitPrompt` hook can only allow/deny a prompt (no context injection), so
`sessionStart` is the right event for a reminder. Restart the Cursor session after copying.
