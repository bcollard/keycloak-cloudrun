terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "6.42.0"
    }
  }

  backend "gcs" {
    bucket  = "tf-state-bco-scripts-kong-gcp"
    prefix = "terraform/bco/keycloak-cloudrun"
    credentials = "tf-state-backend-kong-scripts.json"
  }

  required_version = ">= 1.10"
}
