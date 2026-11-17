#!/usr/bin/env bash
# Integration test on a private tmux server (never touches your own session).
set -u

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
BIN="$ROOT/bin/tmux-bell"
SOCK="attn-test-$$"
fail=0

t() { tmux -L "$SOCK" "$@"; }
ok()   { echo "ok   - $1"; }
bad()  { echo "FAIL - $1"; fail=1; }
check() { if eval "$2"; then ok "$1"; else bad "$1"; fi; }

cleanup() {
  [ -n "${CLIENT_PID:-}" ] && kill "$CLIENT_PID" 2>/dev/null
  t kill-server 2>/dev/null
  rm -rf "${TMPDIR:-/tmp}/tmux-bell-$(id -u)/"*"" 2>/dev/null
}
trap cleanup EXIT

t -f /dev/null new-session -d -s t -x 100 -y 24
t set -g @bell-on-seconds 0.2
t set -g @bell-off-seconds 0.2
t set -g window-status-current-format 'CUSTOM-#I'
W0=$(t display -p -t t:0 '#{window_id}')
W1=$(t new-window -d -P -F '#{window_id}')
# A control-mode client counts as an attached client for #{session_attached}.
(sleep 120 | t -C attach -t t) >/dev/null 2>&1 &
CLIENT_PID=$!
sleep 0.5

# Run the CLI against the private server.
SERVER_ENV="$(t display -p '#{socket_path},#{pid},0')"
run() { TMUX="$SERVER_ENV" TMUX_PANE="" "$BIN" "$@"; }
fmt() { t show-options -wqv -t "$1" window-status-format; }

# 1. start blinks the background window using the derived format
run start -t "$W1"
sleep 0.1
check "blink applies window-status-current-format" "[ \"\$(fmt $W1)\" = 'CUSTOM-#I' ]"
check "status reports blinking" "run status -t $W1"

# 2. no stacked loops
PIDFILE_GLOB="${TMPDIR:-/tmp}/tmux-bell-$(id -u)/*-${W1#@}.pid"; PID_BEFORE=$(cat $PIDFILE_GLOB); run start -t "$W1"
check "second start does not stack loops" "[ \"\$(cat $PIDFILE_GLOB 2>/dev/null)\" = \"\$PID_BEFORE\" ]"

# 3. stop clears the override
run stop -t "$W1"
sleep 0.1
check "stop clears format override" "[ -z \"\$(fmt $W1)\" ]"
check "status reports not blinking" "! run status -t $W1"

# 4. extra positional JSON argument is ignored (Codex style)
out=$(run start '{"type":"agent-turn-complete"}' -t "$W1" 2>&1)
check "JSON positional arg ignored, no output" "[ -z \"\$out\" ] && run status -t $W1"
run stop -t "$W1"

# 5. --if-inactive skips the focused window, starts a background one
t select-window -t "$W0"
sleep 0.2
run start --if-inactive -t "$W0"
check "--if-inactive ignores focused window" "! run status -t $W0"
run start --if-inactive -t "$W1"
check "--if-inactive blinks background window" "run status -t $W1"
sleep 0.3   # let the loop observe the window as inactive before we navigate into it

# 6. loop self-stops when the user navigates into the window
t select-window -t "$W1"
sleep 3
check "loop stops after navigating into window" "! run status -t $W1 && [ -z \"\$(fmt $W1)\" ]"

# 7. focus hook (stop-for-pane) clears immediately
t select-window -t "$W0"
sleep 0.2
run start -t "$W1"
P1=$(t display -p -t "$W1" '#{pane_id}')
run stop-for-pane -t "$P1"
check "stop-for-pane stops the loop" "! run status -t $W1"

# 8. bell hook: background window blinks, focused window does not
TMUX="$SERVER_ENV" "$ROOT/tmux-bell.tmux"
check "plugin entry sets alert-bell hook" "t show-hooks -g | grep -q alert-bell"
check "plugin entry sets pane-focus-in hook" "t show-hooks -gw | grep -q pane-focus-in"
check "plugin entry enables focus-events" "[ \"\$(t show-options -gv focus-events)\" = on ]"
P1=$(t display -p -t "$W1" '#{pane_id}')
t send-keys -t "$P1" "printf '\\a'" Enter
for _ in 1 2 3 4 5 6 7 8 9 10; do run status -t "$W1" && break; sleep 0.3; done
check "bell in background window blinks it" "run status -t $W1"
run stop -t "$W1"

# 9. outside tmux: silent, exit 0
out=$(env -u TMUX -u TMUX_PANE "$BIN" start 2>&1); rc=$?
check "outside tmux: exit 0 and silent" "[ \$rc -eq 0 ] && [ -z \"\$out\" ]"

# 10. bad usage
"$BIN" bogus >/dev/null 2>&1
check "unknown command exits non-zero" "[ \$? -ne 0 ]"

exit $fail
