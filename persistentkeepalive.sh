#!/bin/sh

sleep 15;
PERSISTENT_KEEP_ALIVE=$(cat /etc/wireguard/wg0.conf | grep PersistentKeepalive | awk '{print $3}');
WG_SERVER_IP="$(cat /etc/wireguard/wg0.conf | grep Address | awk '{print $3}' | cut -d . -f1-3).1";
ping -s 0 -I wg0 -i $PERSISTENT_KEEP_ALIVE $WG_SERVER_IP
