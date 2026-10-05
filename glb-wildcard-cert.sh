#!/usr/bin/env bash
set -euo pipefail

: "${DNS_ZONE_NAME:?DNS_ZONE_NAME must be set}"
: "${GCP_PROJECT_DNS:?GCP_PROJECT_DNS must be set}"
: "${GCP_CREDENTIALS_FILE:?GCP_CREDENTIALS_FILE must be set}"

##################################
# Wildcard certificate
# with the lego CLI
##################################
GCE_PROJECT="$GCP_PROJECT_DNS" \
GCE_SERVICE_ACCOUNT_FILE="$GCP_CREDENTIALS_FILE" \
lego run --email baptiste.collard@gmail.com --dns gcloud -d "*.${DNS_ZONE_NAME}" --accept-tos --path ./.lego --dns.resolvers 8.8.8.8:53,1.1.1.1:53

