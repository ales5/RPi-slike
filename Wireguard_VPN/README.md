https://github.com/linuxserver/docker-wireguard


- Shell access whilst the container is running:

docker exec -it wireguard /bin/bash

- To monitor the logs of the container in realtime:

docker logs -f wireguard

- Container version number:

docker inspect -f '{{ index .Config.Labels "build_version" }}' wireguard

- Image version number:

docker inspect -f '{{ index .Config.Labels "build_version" }}' lscr.io/linuxserver/wireguard:latest



- Update images:

    - All images:

    docker-compose pull

    - Single image:

    docker-compose pull wireguard

- Update containers:

    - All containers:

    docker-compose up -d

    - Single container:

    docker-compose up -d wireguard

- You can also remove the old dangling images:

docker image prune


Parameter 	Function
-p 51820:51820/udp 	wireguard port
-e PUID=1000 	for UserID - see below for explanation
-e PGID=1000 	for GroupID - see below for explanation
-e TZ=Etc/UTC 	specify a timezone to use, see this list.
-e SERVERURL=wireguard.domain.com 	External IP or domain name for docker host. Used in server mode. If set to auto, the container will try to determine and set the external IP automatically
-e SERVERPORT=51820 	External port for docker host. Used in server mode.
-e PEERS=1 	Number of peers to create confs for. Required for server mode. Can also be a list of names: myPC,myPhone,myTablet (alphanumeric only)
-e PEERDNS=auto 	DNS server set in peer/client configs (can be set as 8.8.8.8). Used in server mode. Defaults to auto, which uses wireguard docker host's DNS via included CoreDNS forward.
-e INTERNAL_SUBNET=10.13.13.0 	Internal subnet for the wireguard and server and peers (only change if it clashes). Used in server mode.
-e ALLOWEDIPS=0.0.0.0/0 	The IPs/Ranges that the peers will be able to reach using the VPN connection. If not specified the default value is: '0.0.0.0/0, ::0/0' This will cause ALL traffic to route through the VPN, if you want split tunneling, set this to only the IPs you would like to use the tunnel AND the ip of the server's WG ip, such as 10.13.13.1.
-e PERSISTENTKEEPALIVE_PEERS= 	Set to all or a list of comma separated peers (ie. 1,4,laptop) for the wireguard server to send keepalive packets to listed peers every 25 seconds. Useful if server is accessed via domain name and has dynamic IP. Used only in server mode.
-e LOG_CONFS=true 	Generated QR codes will be displayed in the docker log. Set to false to skip log output.
-v /config 	Contains all relevant configuration files.
-v /lib/modules 	Path to host kernel module for situations where it's not already loaded.
--sysctl= 	Required for client mode.
--read-only=true 	Run container with a read-only filesystem. Please read the docs.
--cap-add=NET_ADMIN 	Neccessary for Wireguard to create its VPN interface.
--cap-add=SYS_MODULE 	Neccessary for loading Wireguard kernel module if it's not already loaded.