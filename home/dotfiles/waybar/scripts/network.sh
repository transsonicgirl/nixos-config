#!/bin/sh
# Network stats in MB/s with fixed-width output for consistent pill size.
# Uses second-granularity timestamps to avoid bash integer overflow.

INTERFACE="enp8s0"
CACHE="/tmp/waybar_net_${INTERFACE}"

RX_NOW=$(awk "/^ *${INTERFACE}:/ {print \$2}" /proc/net/dev 2>/dev/null)
TX_NOW=$(awk "/^ *${INTERFACE}:/ {print \$10}" /proc/net/dev 2>/dev/null)
TIME_NOW=$(date +%s)

if [ -z "$RX_NOW" ]; then
    echo "no interface"
    rm -f "$CACHE"
    exit 0
fi

if [ -f "$CACHE" ]; then
    read -r RX_PREV TX_PREV TIME_PREV < "$CACHE"
    ELAPSED=$(( TIME_NOW - TIME_PREV ))

    if [ "$ELAPSED" -gt 0 ]; then
        RX_MB=$(awk "BEGIN { printf \"%.1f\", ($RX_NOW - $RX_PREV) / $ELAPSED / 1048576 }")
        TX_MB=$(awk "BEGIN { printf \"%.1f\", ($TX_NOW - $TX_PREV) / $ELAPSED / 1048576 }")
    else
        RX_MB="0.0"
        TX_MB="0.0"
    fi
else
    RX_MB="0.0"
    TX_MB="0.0"
fi

echo "$RX_NOW $TX_NOW $TIME_NOW" > "$CACHE"

IP=$(ip addr show "$INTERFACE" 2>/dev/null | awk '/inet / {split($2,a,"/"); print a[1]}')
[ -z "$IP" ] && IP="no ip"

printf "$IP"
