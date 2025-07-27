
########################################################################################
# set static IP addresses via NetworkManager for Wifi in Eth interfaces

wifiName="Doma"
ethConName=""

staticIPWifi="192.168.64.154/24"
staticIPEth="192.168.64.155/24"
IPGateway="192.168.64.1"
IPDNS="8.8.8.8"

nmcli con mod $(wifiName) \
  ipv4.addresses $(staticIPWifi) \
  ipv4.gateway $(IPGateway) \
  ipv4.dns $(IPDNS) \
  ipv4.method manual

nmcli con mod $(ethConName) \
  ipv4.addresses $(staticIPEth) \
  ipv4.gateway $(IPGateway) \
  ipv4.dns $(IPDNS) \
  ipv4.method manual

sudo systemctl restart NetworkManager.service




########################################################################################
# Install Docker (pimylifeup.com)
curl -sSL https://get.docker.com | sh
sudo usermod -aG docker $USER # add user to the docker group (if this is not done then only docker user can interact with Docker)

# Install Docker compose (https://docs.docker.com/compose/install/standalone/)
sudo curl -SL https://github.com/docker/compose/releases/download/v2.39.1/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

########################################################################################
# Set VPN server

mkdir Wireguard_VPN
cd Wireguard_VPN

echo 'version: "3.8"

services:
  wireguard:
    image: lscr.io/linuxserver/wireguard:latest
    container_name: wireguard
    cap_add:
      - NET_ADMIN        # manipulate networking
      - SYS_MODULE       # optional; load kernel modules
    environment:
      - PUID=1000        # your Pi user’s UID
      - PGID=1000        # your Pi user’s GID
      - TZ=Europe/Ljubljana
      - SERVERURL=your.ddns.or.static.ip    # optional; e.g. vpn.example.com
      - SERVERPORT=51820 # optional; default WireGuard port
      - PEERS=1          # optional; number of peer configs to generate
      - PEERDNS=auto     # optional; push host DNS to clients
      # - INTERNAL_SUBNET=10.13.13.0/24  # optional; custom subnet
      # - ALLOWEDIPS=0.0.0.0/0          # optional; what clients are allowed to route
      - PERSISTENTKEEPALIVE_PEERS= #optional
      - LOG_CONFS=true #optional
    volumes:
      - ./config:/config
      # - /lib/modules:/lib/modules:ro
    ports:
      - 51820:51820/udp
    sysctls:
      - net.ipv4.conf.all.src_valid_mark=1
    restart: unless-stopped' > docker-compose.yml


