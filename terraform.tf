terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.42.0"
    }
  }

  # Partial configuration: bucket, prefix and credentials come from backend.hcl
  # (see backend.hcl.example), passed by `make tfi`.
  backend "gcs" {}

  required_version = ">= 1.10"
}
