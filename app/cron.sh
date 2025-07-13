#!/bin/sh
set -a

# update ca-certificates on container startup
apk add --update-cache --upgrade apk-tools ca-certificates
#RUN it once to initiate
MODE=run /app/run.sh

crond -f
