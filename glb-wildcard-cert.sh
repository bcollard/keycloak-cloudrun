
# VARS
export GCP_PROJECT=personal-218506
export GCP_CREDENTIALS_FILE=/Users/baptiste.collard@konghq.com/projects/private/kind-on-lima/credentials.json


##################################
# Wildcard certificate
# with the lego CLI
##################################
GCE_PROJECT=$GCP_PROJECT \
GCE_SERVICE_ACCOUNT_FILE=$GCP_CREDENTIALS_FILE \
lego --email baptiste.collard@gmail.com --dns gcloud -d "*.${DNS_ZONE_NAME}" -a run

