#!/bin/sh
# Steam launch-option wrapper:  moza-fh6-wrap %command%
#
# Runs the axis shim only for as long as the game does, so no other game ever
# sees the extra device and there is no system-wide state to undo.
set -e

REAL_VIDPID=0x346e/0x0004   # the actual MOZA R5 base
SHIM_VIDPID=0x046d/0xc24f   # what the shim presents itself as (Logitech G29)

# Hide the real wheel from this process tree only. Without it the game sees two
# wheels and may bind to the one it cannot use. Per-process, so nothing else on
# the system is affected.
SDL_JOYSTICK_BLACKLIST_DEVICES="$REAL_VIDPID"

# SDL already knows the G29 is a wheel, so this is belt and braces -- but if the
# shim's identity is ever changed to something SDL does not recognise, this is
# what keeps Wine emitting a Simulation Controls collection rather than a
# Generic Desktop / Joystick one.
SDL_JOYSTICK_WHEEL_DEVICES="$SHIM_VIDPID"

export SDL_JOYSTICK_BLACKLIST_DEVICES SDL_JOYSTICK_WHEEL_DEVICES

@shim@ &
shim_pid=$!
trap 'kill "$shim_pid" 2>/dev/null || true' EXIT INT TERM

"$@"
