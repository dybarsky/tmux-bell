# More agents and programs

Claude Code, GitHub Copilot CLI and Gemini CLI are covered in the [README](../README.md#agent-setup). The same rules apply here: `tmux-bell` must be on `PATH` (or use the absolute path of the symlink), every call exits 0 silently outside tmux, and the process must inherit `$TMUX_PANE` (otherwise pass `-t <pane-id>`).

Verify event names against each tool's current docs — they change.

## Codex CLI — `~/.codex/config.toml`

```toml
notify = ["tmux-bell", "start"]
```

Codex appends a JSON payload as the last argument; tmux-bell ignores it. `notify` fires only for `agent-turn-complete`; approval prompts are not delivered to it. The blink clears when you switch to the window.

## aider

```sh
aider --notifications --notifications-command "tmux-bell start"
```

(or `notifications: true` and `notifications-command` in `.aider.conf.yml`).

## Anything else

- Rings the bell: `printf '\a'` — handled by the `alert-bell` hook (`@bell-monitor on`).
- Can run a command: `tmux-bell start`, e.g. `make; tmux-bell start`.
