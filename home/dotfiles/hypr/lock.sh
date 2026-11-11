#!/usr/bin/env bash
# Lock the session and blank the displays after a minute of no input.
# hypridle only runs for the lifetime of the lock.

pidof hyprlock >/dev/null && exit 0

hypridle -c "$HOME/.config/hypr/hypridle-locked.conf" &
idle_pid=$!
trap 'kill "$idle_pid" 2>/dev/null; hyprctl dispatch dpms on' EXIT

hyprlock
