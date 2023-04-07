#!/bin/sh

ENDPOINT=$(cat /etc/wireguard/wg0.conf | grep Endpoint | awk '{print $3}' |cut -d ':' -f1)
IP_GATEWAY=$(route -n | grep 'UG[ \t]' | awk '{print $2}');
route add -host $ENDPOINT gw $IP_GATEWAY
