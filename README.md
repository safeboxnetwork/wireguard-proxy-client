Boringtun based wireguard client for linux. Modifyed Dockerfile to correct borintun-cli install and copy. The sample wireguard config uses a set_gateway script to excluding from the default route the wireguard vpn server.

Needed container parameters:
--cap-add=NET_ADMIN 
--cap-add MKNOD 
--cap-add NET_RAW 
--privileged 
--device=/dev/net/tun 
