#!/bin/sh
# Mullvad VPN status for waybar

if ! command -v mullvad &>/dev/null; then
    echo "mullvad not found"
    exit 0
fi

STATUS=$(mullvad status 2>/dev/null)

if [ -z "$STATUS" ]; then
    echo "VPN unavailable"
    exit 0
fi

# Use ^ anchor so "Disconnected" doesn't match "connected"
if echo "$STATUS" | grep -q "^Connected"; then
    SERVER=$(echo "$STATUS" | grep -oP 'to \K\S+')
    echo "VPN ${SERVER:-on}"
else
    echo "VPN off"
fi
