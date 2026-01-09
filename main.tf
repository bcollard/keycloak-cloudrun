provider "google" {
  project = var.project_id
  region  = var.region
}

###
# Enable necessary APIs
resource "google_project_service" "run" {
  service = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "sqladmin" {
  service = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "vpcaccess" {
  service = "vpcaccess.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "secretmanager" {
  service = "secretmanager.googleapis.com"
  disable_on_destroy = false
}


###
# Cloud SQL
resource "google_sql_database_instance" "instance" {
  name             = "keycloak-cloud-run-postgres-db"
  region           = var.region
  database_version = "POSTGRES_15"
  
  settings {
    tier = "db-f1-micro"
    ip_configuration {
      ipv4_enabled    = true # Enable public IP for easier access/debugging as per blog
      private_network = "projects/${var.project_id}/global/networks/default"
    }
  }

  deletion_protection = false # For demo purposes
  depends_on          = [google_project_service.sqladmin]
}

resource "google_sql_database" "database" {
  name     = "keycloak"
  instance = google_sql_database_instance.instance.name
}

resource "google_sql_user" "users" {
  name     = "keycloak-cloud-run"
  instance = google_sql_database_instance.instance.name
  password = var.db_password
}


###
# Secrets
resource "google_secret_manager_secret" "db_password" {
  secret_id = "keycloak-kong-runlocal-dev-db-pwd"
  replication {
    auto {}
  }
  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "db_password_version" {
  secret      = google_secret_manager_secret.db_password.id
  secret_data = var.db_password
}

resource "google_secret_manager_secret" "keycloak_admin_password" {
  secret_id = "keycloak-kong-runlocal-dev-kc-admin-pwd"
  replication {
    auto {}
  }
  depends_on = [google_project_service.secretmanager]
}

resource "google_secret_manager_secret_version" "keycloak_admin_password_version" {
  secret      = google_secret_manager_secret.keycloak_admin_password.id
  secret_data = var.keycloak_admin_password
}


###
# IAM for Cloud Run
data "google_compute_default_service_account" "default" {
}

resource "google_secret_manager_secret_iam_member" "secret_access_db" {
  secret_id = google_secret_manager_secret.db_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

resource "google_secret_manager_secret_iam_member" "secret_access_admin_pwd" {
  secret_id = google_secret_manager_secret.keycloak_admin_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}

resource "google_project_iam_member" "cloudsql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${data.google_compute_default_service_account.default.email}"
}


###
# Cloud Run Service
resource "google_cloud_run_service" "default" {
  name     = "kong-keycloak-on-cloudrun"
  location = var.region

  template {
    spec {
      container_concurrency = 120
      timeout_seconds       = 60
      
      containers {
        image = "ghcr.io/bcollard/keycloak-cloudrun:${var.keycloak_version}" 
        
        args = ["start", "--optimized"]

        ports {
          name           = "http1"
          container_port = 8080
        }

        resources {
          limits = {
            cpu    = "1000m"
            memory = "1Gi"
          }
        }

        startup_probe {
          initial_delay_seconds = 20
          timeout_seconds       = 5
          period_seconds        = 10
          failure_threshold     = 3
          http_get {
            path = "/health"
            port = 8080
          }
        }
        
        env {
          name  = "KC_DB_URL_HOST"
          value = google_sql_database_instance.instance.private_ip_address
        }
        env {
          name  = "KC_DB_USERNAME"
          value = "keycloak-cloud-run"
        }
        env {
          name  = "KC_HOSTNAME"
          value = "keycloak.kong.runlocal.dev"
        }
        env {
          name  = "KEYCLOAK_ADMIN"
          value = "admin"
        }
        env {
          name  = "KC_PROXY_HEADERS"
          value = "xforwarded"
        }
        env {
          name  = "KC_HTTP_ENABLED"
          value = "true"
        }
        
        # Kept these from original config as they might be needed for the specific image/setup
        # even if not explicitly in the dump env list (which might be truncated or defaults)
        env {
          name  = "KC_DB_URL_DATABASE"
          value = "keycloak"
        }
        env {
          name  = "KC_DB_URL_PORT"
          value = "5432"
        }
        env {
          name  = "KC_DB"
          value = "postgres"
        }
        env {
          name  = "KC_DB_SCHEMA"
          value = "public"
        }
        env {
          name  = "KC_LOG_CONSOLE_OUTPUT"
          value = "json"
        }
        env {
          name  = "KC_PROXY"
          value = "edge"
        }

        # Secrets
        env {
          name = "KC_DB_PASSWORD"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.db_password.secret_id
              key  = "latest"
            }
          }
        }
        env {
          name = "KEYCLOAK_ADMIN_PASSWORD"
          value_from {
            secret_key_ref {
              name = google_secret_manager_secret.keycloak_admin_password.secret_id
              key  = "latest"
            }
          }
        }
      }
      
      service_account_name = data.google_compute_default_service_account.default.email
    }

    metadata {
      annotations = {
        "run.googleapis.com/vpc-access-connector"    = google_vpc_access_connector.connector.name
        "run.googleapis.com/cloudsql-instances"      = google_sql_database_instance.instance.connection_name
        "autoscaling.knative.dev/minScale"           = "1"
        "autoscaling.knative.dev/maxScale"           = "1"
        "run.googleapis.com/startup-cpu-boost"       = "true"
        "run.googleapis.com/execution-environment"   = "gen2"
        "run.googleapis.com/sessionAffinity"         = "true"
        "run.googleapis.com/vpc-access-egress"       = "private-ranges-only"
        "run.googleapis.com/ingress"                 = "internal-and-cloud-load-balancing"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }

  depends_on = [google_project_service.run]
}

# Allow unauthenticated invocations
resource "google_cloud_run_service_iam_member" "public_access" {
  service  = google_cloud_run_service.default.name
  location = google_cloud_run_service.default.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}
