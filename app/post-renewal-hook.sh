#! /usr/bin/env bash
set -Eeuo pipefail

mkdir -p /letsencrypt/certs

cp "$LEGO_CERT_KEY_PATH" /letsencrypt/certs/cert.key
cp "$LEGO_CERT_PATH" /letsencrypt/certs/cert.crt

# chown 1000 is for gitea because it refuses to run as root even in a container
chmod -R 750 /letsencrypt/certs
chown -R root:1000 /letsencrypt/certs

echo "Copied new certificate"


POST_RENEWAL_WEBHOOKS=${POST_RENEWAL_WEBHOOKS:-}
if [[ -n "$POST_RENEWAL_WEBHOOKS" ]]; then
  # Split the string into an array, separator is ;
  IFS=';' read -ra url_array <<< "$POST_RENEWAL_WEBHOOKS"

  echo "Calling each web hook"
  # Iterate over the array and hit each URL without downloading the result
  # Webhooks will be used to reload services inside containers. Only internal urls will be used, so no-check-certificate
  # should allow to recover from expired certificates if that happens for some reason
  # || true is used to allow other hooks to be called if one fails
  for url in "${url_array[@]}"; do
    wget --spider --no-check-certificate "$url" || true
  done
fi;
