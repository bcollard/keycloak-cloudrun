# Keycloak on Cloud Run

## Big picture
DN keycloak.kong.runlocal.dev `->` DNS (private GCP tenant) `->` GLB hosted (Kong tenant) + Certificate `->` Cloud Run (Kong tenant)
  `->` serverless VPC `->` Cloud SQL (Kong tenant)


## Certificate
Got a cert with cert-manager deployed locally, on a KinD clusters, connected to my DNS server for the zone `kong.runlocal.dev`


## Keycloak image
Followed steps at https://blog.ineat-group.com/2023/09/deployer-keycloak-sous-cloudrun/

see also:
- `quarkus.properties`
- `Dockerfile`


## gcloud builds
see also 
- `cloud-builds.yaml`


## Postgres
Running on Google Cloud SQL

see also
- `postgresql-gcloud-description.yaml`

super-admin pwd: `***REMOVED***`

username: `keycloak-cloud-run`  
pwd: `***REMOVED***`


## VPC serverless
see also 
- `vpc-connector.yaml`


## Keycloak
admin user: `admin`  
admin pwd: `***REMOVED***`


## GLB
see also:
- `routing-glb.yaml`
- `urlmap-baptiste-glb-http.yaml`
- `backend-services-glb.yaml`
- `neg-glb.yaml`


## Cloud Run
see also
- `cloudrun-knative-dump.yaml`


## WebAuthN passwordless
In the admin console, go to Authentication -> FLows -> copy the "Browser" flow to a new flow called "Browser with Passkeys"
Set it as default flow for browser
In the admin console, go to Authentication -> Required Actions -> turm on WebAuthn Register and WebauthN Regiter Passwordless
In the admin console, go to Authentication -> Policies -> toggle on "Enable Passkeys"

## Fix for kcadm.sh
In the admin console, go to Authentication -> FLows -> edit the direct grant flow
Disable everything OTP related (it conflicts with kcadm.sh usage)

## Fix for VSCOde as an MCP client
- add the openid scope globally, then to the Client in KC
- increase the access token lifespan to 30min because of the clock skew between the local machine and the cloud run instance
- add a new mapper to the client to inject the audience claim in the access token, with the value of the resource param (example: https://api.adeo.runlocal.dev/mcp-kubernetes); while this is not fixed: https://github.com/keycloak/keycloak/issues/41526
- scopes requested by vscode:
        - openid
        - phone
        - address
        - offline_access
        - organization
        - profile
        - email
        - microprofile-jwt






