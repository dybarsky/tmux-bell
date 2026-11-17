#!/usr/bin/env bash
# TPM entry point: wires the focus and bell hooks. Options:
#   set -g @bell-monitor on|off   blink on terminal bell in a background window (default on)
# See README.md for the rest.

CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
# shellcheck source=scripts/helpers.sh
. "$CURRENT_DIR/scripts/helpers.sh"

BIN="$CURRENT_DIR/bin/tmux-bell"

# Needed so tmux reports pane focus changes (instant stop when you switch to the window).
tmux set-option -g focus-events on
tmux set-hook -g pane-focus-in "run-shell -b \"'$BIN' stop-for-pane -t '#{hook_pane}'\""

if [ "$(get_tmux_option @bell-monitor on)" = "on" ]; then
  # A bell in a background window blinks it; bells in the focused window are ignored
  # (shells beep on tab-completion).
  tmux set-option -gw monitor-bell on
  tmux set-hook -g alert-bell "run-shell -b \"'$BIN' start --if-inactive -t '#{hook_window}'\""
else
  tmux set-hook -gu alert-bell
fi
