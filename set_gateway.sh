#!/bin/sh

IP_GATEWAY=$(route -n | grep 'UG[ \t]' | awk '{print $2}');
route add -host vps.vizpartingatlan.hu gw $IP_GATEWAY
