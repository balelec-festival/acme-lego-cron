#! /usr/bin/env bash
set -Eeuo pipefail

# Will fail is volume is not mounted
chmod 555 "$CERTS_VOLUME"

# If a new cert is available (called from lego after renewal) copy new certs so that next bloc can use them
if [[ -v LEGO_CERT_KEY_PATH && -v LEGO_CERT_PATH ]]; then
  echo "Got new certificate"
  cp "$LEGO_CERT_KEY_PATH" "${CERTS_VOLUME}/cert.key"
  cp "$LEGO_CERT_PATH" "${CERTS_VOLUME}/cert.crt"
fi;

# Is used to create the required chowned certs, either on container restart or after cert renewal
mkdir -p "${CERTS_VOLUME}/owned_by"  # Trick to be sure that folder exist for rm in first run
rm -R "${CERTS_VOLUME}/owned_by"
mkdir -p "${CERTS_VOLUME}/owned_by"
chmod 555 "${CERTS_VOLUME}/owned_by"

# Split the string into an array, separator is ;
IFS=';' read -ra CERT_OWNERS <<< "$CERT_OWNERS"

for owner in "${CERT_OWNERS[@]}"; do
  mkdir -p "${CERTS_VOLUME}/owned_by/${owner}"

  cp "${CERTS_VOLUME}/cert.key" "${CERTS_VOLUME}/owned_by/${owner}/cert.key"
  cp "${CERTS_VOLUME}/cert.crt" "${CERTS_VOLUME}/owned_by/${owner}/cert.crt"

  chmod -R 550 "${CERTS_VOLUME}/owned_by/${owner}"
  chown -R "${owner}:${owner}" "${CERTS_VOLUME}/owned_by/${owner}"
done

echo "Copied & chowned certificates"


# This way, the first container to run (this one and docker-maintenance) will create the folder
mkdir -p "${CERTS_VOLUME}/restart_service"

RESTART_COMMAND_FILE="${CERTS_VOLUME}/restart_service/restart_command"
if [[ -f "$RESTART_COMMAND_FILE" ]]; then
  echo "Restart command file '$RESTART_COMMAND_FILE' already exist, this should not happen"
else
  # Will trigger docker maintenance container to restart the containers that use the SSL certs
  touch "$RESTART_COMMAND_FILE"

  echo "SSL restart command sent"
fi
