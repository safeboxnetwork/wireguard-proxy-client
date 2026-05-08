#!/bin/sh

CONF="/etc/wireguard/${INTERFACE:-wg0}.conf"
IFACE="${INTERFACE:-wg0}"

# Wait for the WireGuard interface to be fully up
echo "WireGuard keepalive monitor: waiting 15s for interface $IFACE to come up..."
sleep 5

PERSISTENT_KEEP_ALIVE=$(grep PersistentKeepalive "$CONF" | awk '{print $3}')
# Prefer the Endpoint IP; fall back to the Address-derived gateway
WG_SERVER_IP=$(grep Endpoint "$CONF" | awk '{print $3}' | cut -d: -f1)
PING=$(ping -c 1 -W 5 "$WG_SERVER_IP" | grep -E '1 packets transmitted, 1 packets received')
if [ ! -z "$PING" ]; then
  WG_SERVER_IP="$(grep Address "$CONF" | awk '{print $3}' | cut -d. -f1-3).1"
fi

PING_INTERVAL=${PERSISTENT_KEEP_ALIVE:-25}
MAX_FAILURES=10
fail_count=0

echo "WireGuard keepalive monitor started (target: $WG_SERVER_IP, interval: ${PING_INTERVAL}s, threshold: $MAX_FAILURES)"

while true; do
  if ping -c 1 -W 5 -I "$IFACE" "$WG_SERVER_IP" > /dev/null 2>&1; then
    fail_count=0
  else
    fail_count=$((fail_count + 1))
    echo "WireGuard keepalive ping failed ($fail_count/$MAX_FAILURES) to $WG_SERVER_IP via $IFACE"
    if [ "$fail_count" -ge "$MAX_FAILURES" ]; then
      echo "WireGuard connection is stuck after $MAX_FAILURES consecutive failures ... forcing container restart..."
      exec killall boringtun
    fi
  fi
  sleep "$PING_INTERVAL"
done