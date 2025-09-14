
# Configure raspi-config -> enalbe ssh, connect to WiFi, locale,..

# fstab configuration
MOUNT_DIR="/mnt/server_slike"
sudo mkdir -p $MOUNT_DIR 
UUID="A00833A2083375FE"
#UUID=$(blkid -o value -s UUID $(lsblk -o NAME,FSTYPE -pn | grep ntfs | awk '{print $1}' | head -n 1))
sudo sh -c "echo \"UUID=$UUID  $MOUNT_DIR  ntfs  defaults,nofail,uid=1000,gid=1000,umask=000  0  2\" >> /etc/fstab"
sudo mount -a


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
# WireGuard server with dynamic No-IP hostname

# To forward between internet interfaces (between eth0 and docker0)
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf


sudo iptables -t nat -A POSTROUTING -s 10.13.13.0/24 -o wlan0 -j MASQUERADE
sudo iptables -t nat -A POSTROUTING -s 10.13.13.0/24 -o eth0 -j MASQUERADE
sudo iptables -A FORWARD -i wg0 -j ACCEPT
sudo iptables -A FORWARD -o wg0 -j ACCEPT
sudo apt install iptables-persistent -y
sudo netfilter-persistent save


echo "Enter your No-IP hostname (e.g., mypi.ddns.net):"
read -r NOIP_HOSTNAME

mkdir -p "./Wireguard_VPN"
cd "./Wireguard_VPN"

cat > docker-compose.yml <<EOF
version: "3.8"


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
      - SERVERURL=$NOIP_HOSTNAME # auto    # optional; e.g. vpn.example.com
      - SERVERPORT=51820 # optional; default WireGuard port
      - PEERS=12          # optional; number of peer configs to generate
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
    restart: unless-stopped
EOF

docker compose up -d

echo "WireGuard container deployed using No-IP hostname: $NOIP_HOSTNAME"



########################################################################################
# Samba server
SAMBA_SERVER_DIR="Samba_sever"
CONTAINER_NAME=samba-server
mkdir -p $SAMBA_SERVER_DIR
cd $SAMBA_SERVER_DIR
# 1. Create Dockerfile
cat > Dockerfile <<'EOF'
FROM debian:stable-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y samba samba-common-bin nano && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /data

COPY smb.conf /etc/samba/smb.conf

EXPOSE 137 138 139 445

CMD ["/usr/sbin/smbd", "-F", "--no-process-group"] 
# -F: run in the foreground (so Docker can manage it)
EOF

# 2. Create Samba configuration file
cat > smb.conf <<'EOF'
[global]
   server string = Pi Samba Server
   log file = /var/log/samba/log.%m
   max log size = 50
   map to guest = Bad User
   usershare allow guests = yes
   passdb backend = tdbsam

[share]
   path = /data
   browsable = yes
   read only = no
   guest ok = no
EOF

# 3. Create Docker Compose file
cat > docker-compose.yml <<EOF
version: "3.9"

services:
  samba:
    build: .
    container_name: $CONTAINER_NAME
    restart: unless-stopped
    ports:
      - "139:139"
      - "445:445"
    volumes:
      - $MOUNT_DIR:/data
EOF

# 4. Build Docker image
docker compose build

# 5. Start container
docker compose up -d

# 6. Prompt for Samba username and password
echo "Enter Samba username to create:"
read -r SAMBA_USER
echo "Enter Samba password:"
read -rs SAMBA_PASS
echo

# 7. Create a Linux user inside the container
docker exec -it "$CONTAINER_NAME" bash -c "adduser --disabled-password --gecos '' $SAMBA_USER"

# 8. Set the Linux user password
docker exec -it "$CONTAINER_NAME" bash -c "echo '$SAMBA_USER:$SAMBA_PASS' | chpasswd"

# 9. Add the user to Samba's password database
docker exec -it "$CONTAINER_NAME" bash -c "
  smbpasswd -a -s $SAMBA_USER <<< \"$SAMBA_PASS
$SAMBA_PASS\"
"

echo "Samba container deployed! Share available at: \\\\<Pi-IP>\\share"



########################################################################################
# FTPS server
FTPS_SERVER_DIR="FTPS_server"
FTPS_CONTAINER_NAME="ftps-server"
mkdir -p "$FTPS_SERVER_DIR"
cd "$FTPS_SERVER_DIR"

# 1. Create Dockerfile
cat > Dockerfile <<'EOF'
FROM debian:stable-slim

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y vsftpd openssl && \
    rm -rf /var/lib/apt/lists/*

RUN mkdir -p /data /etc/ssl/private

# Generate self-signed certificate (for testing; replace with real cert if needed)
RUN openssl req -x509 -nodes -days 1095 -subj "/C=US/ST=State/L=City/O=Org/CN=localhost" \
    -newkey rsa:2048 -keyout /etc/ssl/private/vsftpd.key \
    -out /etc/ssl/private/vsftpd.crt

COPY vsftpd.conf /etc/vsftpd.conf

EXPOSE 21 20 21100-21110

CMD ["/usr/sbin/vsftpd", "/etc/vsftpd.conf"]
EOF

# 2. Create vsftpd configuration file
cat > vsftpd.conf <<'EOF'
listen=YES
listen_ipv6=NO
anonymous_enable=NO
local_enable=YES
write_enable=YES
chroot_local_user=YES
allow_writeable_chroot=YES
pasv_enable=YES
pasv_min_port=21100
pasv_max_port=21110
ssl_enable=YES
rsa_cert_file=/etc/ssl/private/vsftpd.crt
rsa_private_key_file=/etc/ssl/private/vsftpd.key
force_local_data_ssl=YES
force_local_logins_ssl=YES
ssl_ciphers=HIGH
EOF

# 3. Create Docker Compose file
cat > docker-compose.yml <<EOF
version: "3.9"

services:
  ftps:
    build: .
    container_name: $FTPS_CONTAINER_NAME
    restart: unless-stopped
    ports:
      - "21:21"
      - "20:20"
      - "21100-21110:21100-21110"
    volumes:
      - $MOUNT_DIR:/data
EOF

# 4. Build Docker image
docker compose build

# 5. Start container
docker compose up -d

# 6. Prompt for FTPS username and password
echo "Enter FTPS username to create:"
read -r FTPS_USER
echo "Enter FTPS password:"
read -rs FTPS_PASS
echo

# 7. Create user inside container
docker exec -it "$FTPS_CONTAINER_NAME" bash -c "
  adduser --home /data --disabled-password --gecos '' $FTPS_USER && \
  echo '$FTPS_USER:$FTPS_PASS' | chpasswd
"


echo "FTPS container deployed! Connect with:"
echo "Host: <Pi-IP>, Port: 21, Username: $FTPS_USER, Password: [the one you entered], Protocol: FTPS (Explicit)"







########################################################################################
# No-IP DUC client

NOIP_DIR="./NoIP_DUC"
NOIP_CONTAINER_NAME="noip-duc"
mkdir -p "$NOIP_DIR"
cd "$NOIP_DIR"

# Prompt for No-IP credentials and hostname
echo "Enter your No-IP username/email:"
read -r NOIP_USERNAME
echo "Enter your No-IP password:"
read -rs NOIP_PASSWORD
echo
echo "Enter your No-IP hostname(s) (comma-separated if multiple, e.g., mypi.ddns.net):"
read -r NOIP_HOSTNAMES

# Create env file
cat > noip-duc.env <<EOF
NOIP_USERNAME=$NOIP_USERNAME
NOIP_PASSWORD=$NOIP_PASSWORD
NOIP_HOSTNAMES=$NOIP_HOSTNAMES
EOF

# Create docker-compose.yml using official GitHub template
cat > docker-compose.yml <<EOF
services:
  noip-duc:
    container_name: $NOIP_CONTAINER_NAME
    image: ghcr.io/noipcom/noip-duc:latest
    env_file: noip-duc.env
    restart: unless-stopped
    networks:
      - noip-duc

networks:
  noip-duc:
    driver: bridge
EOF

# Start the container
docker compose up -d

echo "No-IP DUC container deployed and running. Check logs with:"
echo "docker logs -f $NOIP_CONTAINER_NAME"




########################################################################################
# Install GUI
sudo apt install raspberrypi-ui-mods
sudo apt install xinit
startx


########################################################################################
# Install firefox
sudo apt install firefox-esr
firefox







