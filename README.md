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

