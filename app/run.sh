#! /usr/bin/env bash
set -Eeuo pipefail

error() {
    echo -e "[$( date '+%Y-%m-%d %H:%M:%S' )] $1" >&2
}

LEGO_ARGS=${LEGO_ARGS-}
MODE=${MODE-renew}
KEY_TYPE=${KEY_TYPE-ec384}

# Get endpoint
STAGING=${STAGING:-0}
ENDPOINT='https://acme-v02.api.letsencrypt.org/directory'
if [[ "1" == "$STAGING" ]]; then
  ENDPOINT='https://acme-staging-v02.api.letsencrypt.org/directory'
fi;

# Stop here if no domains were given as arguments
DOMAINS=${DOMAINS:-}
DOMAINS_LEGO_ARG=""
if [[ -n "$DOMAINS" ]]; then
  # Split the string into an array, separator is ;
  IFS=';' read -ra DOMAINS <<< "$DOMAINS"

  # Iterate over the array and hit each URL without downloading the result
  for domain in "${DOMAINS[@]}"; do
    DOMAINS_LEGO_ARG="$DOMAINS_LEGO_ARG --domains $domain"
  done
else
  error 'Domain(s) not provided.' && exit 1
fi;

EMAIL_ADDRESS=${EMAIL_ADDRESS:-}
# Stop here if no email address given as arguments
if [[ -z "$EMAIL_ADDRESS" ]]; then
  error 'Email Address not provided.' && exit 1
fi;


if [[ -n "$PROVIDER" ]]; then
	echo "Using dns provider $PROVIDER."
	DNS_TIMEOUT=${DNS_TIMEOUT:-10}

	/lego --server $ENDPOINT --path /letsencrypt --accept-tos --key-type="$KEY_TYPE" $DOMAINS_LEGO_ARG \
	--email "$EMAIL_ADDRESS" --pem --dns "$PROVIDER" --dns-timeout "$DNS_TIMEOUT" \
	"$MODE" "--${MODE}-hook=./post-renewal-hook.sh" $LEGO_ARGS
else
	/lego --server $ENDPOINT --path /letsencrypt --accept-tos --key-type="$KEY_TYPE" $DOMAINS_LEGO_ARG \
	--email "$EMAIL_ADDRESS" --pem "$MODE" "--${MODE}-hook=./post-renewal-hook.sh" $LEGO_ARGS
fi
