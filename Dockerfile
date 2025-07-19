ARG VERSION
FROM goacme/lego:${VERSION} AS lego

ARG VERSION
FROM alpine:3
LABEL maintainer="sysadmin@balelec.ch"
RUN apk upgrade --no-cache && apk add ca-certificates tzdata bash coreutils dumb-init python3 --no-cache

COPY crontab /var/spool/cron/crontabs/root
RUN chown -R root:root /var/spool/cron/crontabs/root && chmod -R 640 /var/spool/cron/crontabs/root

WORKDIR /opt/
COPY --from=lego /lego lego
COPY app app

ENTRYPOINT ["dumb-init","--", "./app/entrypoint.sh"]
