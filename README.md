# tmux-bell

Blink a tmux window's status-bar tab when something running in it needs you — an AI agent waiting for approval or finished with its turn, or any program that rings the terminal bell. The blink stops when you switch to the window (or when the agent says you answered).

Works with Claude Code, Codex CLI, Gemini CLI, aider, and anything that can run a command or ring the bell. See [docs/agents.md](docs/agents.md).

## Install (TPM)

```tmux
set -g @plugin '<github-user>/tmux-bell'   # or any git URL
```

Press `prefix + I`. Then put the CLI on your `PATH` so agent configs can call it:

```sh
ln -s ~/.tmux/plugins/tmux-bell/bin/tmux-bell ~/.local/bin/tmux-bell
```

The plugin turns on `focus-events`, adds a `pane-focus-in` hook (instant stop when you switch to a window) and an `alert-bell` hook.

## CLI

```
tmux-bell start [-t target] [--if-inactive]   begin blinking
tmux-bell stop  [-t target]                    stop
tmux-bell status [-t target]                   exit 0 if blinking
```

The target defaults to `$TMUX_PANE` (the pane the command runs in), so hooks "just work". It is silent and exits 0 outside tmux, and ignores extra arguments (Codex appends a JSON payload).

## Options

| Option | Default | |
|---|---|---|
| `@bell-monitor` | `on` | blink a *background* window when a program rings the bell (`printf '\a'`); bells in the focused window are ignored |
| `@bell-on-seconds` | `0.8` | lit time |
| `@bell-off-seconds` | `0.8` | dark time |
| `@bell-timeout-minutes` | `180` | safety stop |
| `@bell-format` | *(empty)* | blink format; empty = your `window-status-current-format`, so the tab flashes like the active one and follows your theme |

## How it works

A detached loop swaps the window's `window-status-format` on and off. It ends when the window goes background→focused, when `stop` is called, or on timeout. State lives in `$TMPDIR/tmux-bell-<uid>/`, keyed by tmux server and window.

## Test

`bash tests/test.sh` runs against a private tmux server and does not touch your sessions.
