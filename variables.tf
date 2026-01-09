variable "account_name" {
  description = "Name of the Konnect account"
  type        = string
}
variable "project_name" {
  description = "Name of the project in Konnect"
  type        = string
}


variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "region" {
  description = "The GCP region"
  type        = string
  default     = "europe-west9"
}

variable "keycloak_version" {
  description = "The version of Keycloak to deploy"
  type        = string
  default     = "26.2"
}

variable "db_password" {
  description = "The password for the database user"
  type        = string
  sensitive   = true
}

variable "keycloak_admin" {
  description = "The Keycloak admin username"
  type        = string
  default     = "admin"
}

variable "keycloak_admin_password" {
  description = "The Keycloak admin password"
  type        = string
  sensitive   = true
}
