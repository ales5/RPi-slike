
# Configure raspi-config -> enalbe ssh, connect to WiFi, locale,..


# fstab configuration
MOUNT_DIR ="/mnt/server_slike"
sudo mkdir -p $MOUNT_DIR 
UUID="XXXX-XXXX"
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

# To forward between internet interfaces (between eth0 and docker0)
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf


mkdir ~/Wireguard_VPN
cd ~/Wireguard_VPN

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
      - SERVERURL=auto    # optional; e.g. vpn.example.com
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


docker compose up -d



########################################################################################
# Samba server
SAMBA_SERVER_DIR="~/Samba_sever"
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

CMD ["/usr/sbin/smbd", "-FS", "--no-process-group"]
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
      - $MOUNT_POINT:/data
EOF

# 4. Build Docker image
docker-compose build

# 5. Start container
docker-compose up -d

# 6. Prompt for Samba username and password
echo "Enter Samba username to create:"
read -r SAMBA_USER
echo "Enter Samba password:"
read -rs SAMBA_PASS
echo

# 7. Create a Linux user inside the container
docker exec -it "$CONTAINER_NAME" bash -c "
  adduser --disabled-password --gecos '' $SAMBA_USER
"

# 8. Set the Linux user password
docker exec -it "$CONTAINER_NAME" bash -c "
  echo '$SAMBA_USER:$SAMBA_PASS' | chpasswd
"

# 9. Add the user to Samba's password database
docker exec -it "$CONTAINER_NAME" bash -c "
  smbpasswd -a -s $SAMBA_USER <<< \"$SAMBA_PASS
$SAMBA_PASS\"
"

echo "Samba container deployed! Share available at: \\\\<Pi-IP>\\share"



########################################################################################
# FTP server


