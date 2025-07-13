ARG VERSION
FROM goacme/lego:${VERSION} AS lego

ARG VERSION
FROM alpine:3
LABEL maintainer="adrien@icefo.net"
RUN apk upgrade --no-cache && apk add ca-certificates tzdata wget bash --no-cache

COPY --from=lego /lego /
COPY app/*.sh /app/
RUN chown -R root:root /app
RUN chmod -R 550 /app
RUN chmod +x /app/*.sh
RUN dos2unix /app/*.sh

RUN mkdir -p /letsencrypt

COPY crontab /var/spool/cron/crontabs/root
RUN chown -R root:root /var/spool/cron/crontabs/root && chmod -R 640 /var/spool/cron/crontabs/root

# This is the only signal from the docker host that appears to stop crond
STOPSIGNAL SIGKILL

RUN ls -al /app
WORKDIR /app
ENTRYPOINT [ "./cron.sh", ""]
