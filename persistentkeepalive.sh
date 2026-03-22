#!/bin/sh

CONF="/etc/wireguard/${INTERFACE:-wg0}.conf"
IFACE="${INTERFACE:-wg0}"

# Wait for the WireGuard interface to be fully up
echo "WireGuard keepalive monitor: waiting 15s for interface $IFACE to come up..."
sleep 15

PERSISTENT_KEEP_ALIVE=$(grep PersistentKeepalive "$CONF" | awk '{print $3}')
# Prefer the Endpoint IP; fall back to the Address-derived gateway
WG_SERVER_IP=$(grep Endpoint "$CONF" | awk '{print $3}' | cut -d: -f1)
if [ -z "$WG_SERVER_IP" ]; then
  WG_SERVER_IP="$(grep Address "$CONF" | awk '{print $3}' | cut -d. -f1-3).1"
fi

PING_INTERVAL=${PERSISTENT_KEEP_ALIVE:-25}
MAX_FAILURES=3
fail_count=0

echo "WireGuard keepalive monitor started (target: $WG_SERVER_IP, interval: ${PING_INTERVAL}s, threshold: $MAX_FAILURES)"

while true; do
  if ping -c 1 -W 5 -I "$IFACE" "$WG_SERVER_IP" > /dev/null 2>&1; then
    fail_count=0
  else
    fail_count=$((fail_count + 1))
    echo "WireGuard keepalive ping failed ($fail_count/$MAX_FAILURES) to $WG_SERVER_IP via $IFACE"
    if [ "$fail_count" -ge "$MAX_FAILURES" ]; then
      echo "WireGuard connection is stuck after $MAX_FAILURES consecutive failures — forcing container restart..."
      # SIGKILL tini (PID 1) so the container exits with code 137 and Docker restarts it
      kill -9 1
      exit 1
    fi
  fi
  sleep "$PING_INTERVAL"
done
