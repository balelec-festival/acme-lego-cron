#! /usr/bin/env bash
set -Eeuo pipefail

# update ca-certificates on container startup
apk add --update-cache --upgrade apk-tools ca-certificates

#RUN it once to initiate
python3 -m "app.main"

exec crond -f
