# 1. VPC Connector
tf import -var-file=./values.tfvars google_vpc_access_connector.connector projects/${PROJECT_ID}/locations/${REGION}/connectors/keycloak-cloud-run-to-sql

# 2. Cloud SQL Instance
tf import -var-file=./values.tfvars google_sql_database_instance.instance projects/${PROJECT_ID}/instances/keycloak-cloud-run-postgres-db

# 3. Cloud SQL Database
tf import -var-file=./values.tfvars google_sql_database.database projects/${PROJECT_ID}/instances/keycloak-cloud-run-postgres-db/databases/keycloak

# 4. Cloud SQL User
tf import -var-file=./values.tfvars google_sql_user.users ${PROJECT_ID}/keycloak-cloud-run-postgres-db/keycloak-cloud-run

# 5. Secrets (Secret Manager)
tf import -var-file=./values.tfvars google_secret_manager_secret.db_password projects/${PROJECT_ID}/secrets/keycloak-kong-runlocal-dev-db-pwd
tf import -var-file=./values.tfvars google_secret_manager_secret_version.db_password_version projects/${PROJECT_ID}/secrets/keycloak-kong-runlocal-dev-db-pwd/versions/latest

tf import -var-file=./values.tfvars google_secret_manager_secret.keycloak_admin_password projects/${PROJECT_ID}/secrets/keycloak-kong-runlocal-dev-kc-admin-pwd
tf import -var-file=./values.tfvars google_secret_manager_secret_version.keycloak_admin_password_version projects/${PROJECT_ID}/secrets/keycloak-kong-runlocal-dev-kc-admin-pwd/versions/latest

# 7. Cloud Run Service
tf import -var-file=./values.tfvars google_cloud_run_service.default locations/${REGION}/namespaces/${PROJECT_ID}/services/kong-keycloak-on-cloudrun

# 8. Cloud Run Public Access (IAM)
tf import -var-file=./values.tfvars google_cloud_run_service_iam_member.public_access "v1/projects/${PROJECT_ID}/locations/${REGION}/services/kong-keycloak-on-cloudrun roles/run.invoker allUsers"

tf import -var-file=./values.tfvars google_service_account.keycloak_sa projects/${PROJECT_ID}/serviceAccounts/kong-keycloak-on-cloudrun@${PROJECT_ID}.iam.gserviceaccount.com