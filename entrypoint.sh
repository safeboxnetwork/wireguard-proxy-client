#!/usr/bin/env bash

set -e

declare -r WG_INTERFACE=${1:-wg0}

KEEPALIVE_PID=""
WG_PID=""

function shutdown_wg() {
  echo "Shutting down WireGuard (boringtun)"
  [ -n "$KEEPALIVE_PID" ] && kill "$KEEPALIVE_PID" 2>/dev/null || true
  wg-quick down "$1"
  exit 0
}

function start_wg() {
  echo "Starting WireGuard (boringtun)"
  # Run wg-quick in the background so we retain control of this shell
  wg-quick up "$1" &
  WG_PID=$!

  echo "Starting keepalive connection monitor"
  /etc/wireguard/persistentkeepalive.sh &
  KEEPALIVE_PID=$!

  # Handle clean shutdown signals
  trap 'shutdown_wg "$1"' SIGTERM SIGINT SIGQUIT

  # Block until the keepalive monitor exits.
  # It exits with code 1 only when the connection is stuck — trigger a restart.
  if ! wait "$KEEPALIVE_PID"; then
    echo "WireGuard keepalive monitor detected a stuck connection — forcing container restart (exit 1)"
    [ -n "$WG_PID" ] && kill -9 "$WG_PID" 2>/dev/null || true
    exit 1
  fi

  # Keepalive exited cleanly (shouldn't happen); wait for wg process too
  wait "$WG_PID" || exit $?
}

if [ -f "/etc/wireguard/${WG_INTERFACE}.conf" ]; then
  start_wg "${WG_INTERFACE}"
else
  exec "$@"
fi
