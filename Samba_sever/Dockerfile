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
