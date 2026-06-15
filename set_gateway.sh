#!/bin/sh

ENDPOINT=$(cat /etc/wireguard/wg0.conf | grep Endpoint | awk '{print $3}' |cut -d ':' -f1);
IP_GATEWAY=$(route -n | grep 'UG[ \t]' | awk '{print $2}');
route add -host $ENDPOINT gw $IP_GATEWAY;

# temporary added iptables lines
iptables-legacy -t nat -I PREROUTING -i wg0 -p tcp -m tcp --dport 80 -j DNAT --to-destination 172.18.103.2:80
iptables-legacy -t nat -I PREROUTING -i wg0 -p tcp -m tcp --dport 443 -j DNAT --to-destination 172.18.103.2:443
iptables-legacy -t nat -I POSTROUTING -d 172.18.103.0/24 -p tcp -m tcp --dport 80 -j MASQUERADE
iptables-legacy -t nat -I POSTROUTING -d 172.18.103.0/24 -p tcp -m tcp --dport 443 -j MASQUERADE
# need to remove after service-exec go update

/etc/wireguard/persistentkeepalive.sh &
