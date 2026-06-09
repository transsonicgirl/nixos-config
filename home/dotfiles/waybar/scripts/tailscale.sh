#!/bin/sh
# Tailscale status for waybar custom/tailscale module
# Output matches i3status format: "Tailscale <ip>" or "Tailscale Down"

ip=$(ip addr show tailscale0 2>/dev/null | grep 'inet ' | awk '{print $2}' | cut -d/ -f1)

if [ -n "$ip" ]; then
    echo "TS $ip"
else
    echo "TS Down"
fi
