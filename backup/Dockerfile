FROM alpine:3.20

RUN apk add --no-cache \
    bash \
    ca-certificates \
    coreutils \
    mariadb-client \
    rclone \
    tzdata

COPY backup-loop.sh /usr/local/bin/backup-loop.sh
COPY backup-once.sh /usr/local/bin/backup-once.sh
RUN chmod +x /usr/local/bin/backup-loop.sh
RUN chmod +x /usr/local/bin/backup-once.sh

ENTRYPOINT ["/usr/local/bin/backup-loop.sh"]
