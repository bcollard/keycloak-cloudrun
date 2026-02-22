provider "google" {
  project = var.project_id
  region  = var.region
  zone    = var.gcp_zone

  default_labels = {
    "managed-by"      = "terraform"
    "owner"           = "baptiste-collard"
    "end-date"         = "2026-12-31"
    "weekend-shutdown" = "yes"
  }
}

