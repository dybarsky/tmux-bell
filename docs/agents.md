# Agent setup

All snippets assume `tmux-bell` is on `PATH` (see README). If an agent's hooks don't see your `PATH`, use the absolute path of the symlink. Every call exits 0 silently outside tmux. The agent's process must inherit `$TMUX_PANE`; if it doesn't, pass `-t <pane-id>`.

Verify event names against each tool's current docs — they change.

## Claude Code — `~/.claude/settings.json`

```json
{
  "hooks": {
    "Notification":     [{ "hooks": [{ "type": "command", "command": "tmux-bell start" }] }],
    "Stop":             [{ "hooks": [{ "type": "command", "command": "tmux-bell start" }] }],
    "UserPromptSubmit": [{ "hooks": [{ "type": "command", "command": "tmux-bell stop" }] }],
    "PostToolUse":      [{ "hooks": [{ "type": "command", "command": "tmux-bell stop" }] }]
  }
}
```

`Notification` = permission prompt / idle; `Stop` = turn finished; the two stop hooks clear it once you answer or a tool you approved has run.

## Codex CLI — `~/.codex/config.toml`

```toml
notify = ["tmux-bell", "start"]
```

Codex appends a JSON payload as the last argument; tmux-bell ignores it. `notify` fires only for `agent-turn-complete`; approval prompts are not delivered to it. The blink clears when you switch to the window.

## Gemini CLI — `~/.gemini/settings.json`

```json
{
  "hooks": {
    "Notification": [{ "matcher": "*", "hooks": [{ "type": "command", "command": "tmux-bell start" }] }],
    "AfterAgent":   [{ "matcher": "*", "hooks": [{ "type": "command", "command": "tmux-bell start" }] }],
    "BeforeAgent":  [{ "matcher": "*", "hooks": [{ "type": "command", "command": "tmux-bell stop" }] }]
  }
}
```

Gemini hooks must print only JSON to stdout; tmux-bell prints nothing. Check whether hooks need to be enabled in your version. `AfterAgent` may not fire for text-only replies.

## aider

```sh
aider --notifications --notifications-command "tmux-bell start"
```

(or `notifications: true` and `notifications-command` in `.aider.conf.yml`).

## Anything else

- Rings the bell: `printf '\a'` — handled by the `alert-bell` hook (`@bell-monitor on`).
- Can run a command: `tmux-bell start`, e.g. `make; tmux-bell start`.
