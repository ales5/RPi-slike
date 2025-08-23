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
