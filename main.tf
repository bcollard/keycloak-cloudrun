provider "google" {
  project = var.project_id
  region  = var.region
}


resource "google_project_service" "secretmanager" {
  service = "secretmanager.googleapis.com"
  disable_on_destroy = false
}

# Artifact Registry Remote Repository
resource "google_artifact_registry_repository" "github_proxy" {
  location      = var.region
  repository_id = "github-proxy"
  description   = "GitHub Container Registry Proxy"
  format        = "DOCKER"
  mode          = "REMOTE_REPOSITORY"
  remote_repository_config {
    description = "GitHub Container Registry"
    docker_repository {
      custom_repository {
        uri = "https://ghcr.io"
      }
    }
  }
}

###
# VPC Connector
resource "google_vpc_access_connector" "connector" {
  name          = "keycloak-cloud-run-to-sql"
  region        = var.region
  ip_cidr_range = "10.8.240.0/28"
  network       = "default"
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
      private_network = "projects/${var.project_id}/global/networks/default"
      ipv4_enabled    = false
    }
    maintenance_window {
      day = 1
      hour = 0
    }
    deletion_protection_enabled = true
  }

  deletion_protection = true
}

resource "google_sql_database" "database" {
  name     = "keycloak"
  instance = google_sql_database_instance.instance.name
}

resource "google_sql_user" "users" {
  name     = "keycloak-cloud-run"
  instance = google_sql_database_instance.instance.name
  # password = var.db_password
}


###
# Secrets
resource "google_secret_manager_secret" "db_password" {
  secret_id = "keycloak-kong-runlocal-dev-db-pwd"
  replication {
    auto {}
  }
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
}

resource "google_secret_manager_secret_version" "keycloak_admin_password_version" {
  secret      = google_secret_manager_secret.keycloak_admin_password.id
  secret_data = var.keycloak_admin_password
}


###
# IAM for Cloud Run
resource "google_service_account" "keycloak_sa" {
  account_id   = "kong-keycloak-on-cloudrun"
  display_name = "Service Account for Keycloak on Cloud Run"
}

resource "google_secret_manager_secret_iam_member" "secret_access_db" {
  secret_id = google_secret_manager_secret.db_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.keycloak_sa.email}"
}

resource "google_secret_manager_secret_iam_member" "secret_access_admin_pwd" {
  secret_id = google_secret_manager_secret.keycloak_admin_password.id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${google_service_account.keycloak_sa.email}"
}

resource "google_project_iam_member" "artifact_registry_reader" {
  project = var.project_id
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.keycloak_sa.email}"
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
        image = "${var.region}-docker.pkg.dev/${var.project_id}/github-proxy/bcollard/keycloak-cloudrun:${var.keycloak_version}"        
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
          initial_delay_seconds = 21
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
      
      service_account_name = google_service_account.keycloak_sa.email
    }

    metadata {
      annotations = {
        "run.googleapis.com/vpc-access-connector"    = "projects/${var.project_id}/locations/${var.region}/connectors/${google_vpc_access_connector.connector.name}"
        "run.googleapis.com/cloudsql-instances"      = google_sql_database_instance.instance.connection_name
        "run.googleapis.com/client-name"             = "cloud-console"
        "autoscaling.knative.dev/minScale"           = "1"
        "autoscaling.knative.dev/maxScale"           = "1"
        "run.googleapis.com/startup-cpu-boost"       = "true"
        "run.googleapis.com/execution-environment"   = "gen2"
        "run.googleapis.com/sessionAffinity"         = "true"
        "run.googleapis.com/vpc-access-egress"       = "private-ranges-only"
      }
    }
  }

  traffic {
    percent         = 100
    latest_revision = true
  }
}

# Allow unauthenticated invocations
resource "google_cloud_run_service_iam_member" "public_access" {
  service  = google_cloud_run_service.default.name
  location = google_cloud_run_service.default.location
  role     = "roles/run.invoker"
  member   = "allUsers"
}
