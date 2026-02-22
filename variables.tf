variable "account_name" {
  description = "Name of the Konnect account"
  type        = string
}
variable "project_name" {
  description = "Name of the project in Konnect"
  type        = string
}


# GCP
variable "gcp_project" {
  description = "Name of the GCP project"
  type        = string
  default     = "intense-clarity-338816"
}

variable "gcp_region" {
  description = "GCP region"
  type        = string
  default     = "europe-west4"
}

variable "gcp_zone" {
  description = "GCP zone"
  type        = string
  default     = "europe-west4-b"
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

variable "url_map_name" {
  description = "Name of the URL map"
  type        = string
}

variable "target_https_proxy_name" {
  description = "Name of the target HTTPS proxy"
  type        = string
}

variable "forwarding_rule_name" {
  description = "Name of the forwarding rule"
  type        = string
}

variable "forwarding_rule_ip_address" {
  description = "IP address for the global forwarding rule"
  type        = string
}

variable "backend_service_name" {
  description = "Name of the backend service"
  type        = string
}

variable "backend_service_endpoint" {
  description = "Backend service endpoint NEG"
  type        = string
}

variable "ssl_certificate_name" {
  description = "Name of the SSL certificate"
  type        = string
}

variable "ssl_certificate_path" {
  description = "Path to SSL certificate file"
  type        = string
}

variable "ssl_certificate_key_path" {
  description = "Path to SSL certificate private key"
  type        = string
}

variable "keycloak_hostname" {
  description = "Hostname for Keycloak (e.g., keycloak.kong.runlocal.dev)"
  type        = string
}

variable "keycloak_admin_header_value" {
  description = "Secret header value for admin access to Keycloak"
  type        = string
  sensitive   = true
}
