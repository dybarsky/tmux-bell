#!/usr/bin/env bash
# Shared helpers for tmux-bell. Sourced, never executed.

# get_tmux_option <@option> <default> — value of a global tmux option, or the default.
get_tmux_option() {
  local value
  value=$(tmux show-option -gqv "$1" 2>/dev/null)
  printf '%s' "${value:-$2}"
}
