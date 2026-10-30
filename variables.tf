# GCP
variable "gcp_project" {
  description = "ID of the GCP project hosting Cloud Run, Cloud SQL and the load balancer"
  type        = string
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


variable "keycloak_version" {
  description = "The version of Keycloak to deploy"
  type        = string
  default     = "26.6.2"
}

variable "keycloak_image_digest" {
  description = "Optional image digest (sha256:...) to deploy instead of the keycloak_version tag; get it with `make image-digest`"
  type        = string
  default     = null

  validation {
    condition     = var.keycloak_image_digest == null || can(regex("^sha256:[0-9a-f]{64}$", var.keycloak_image_digest))
    error_message = "keycloak_image_digest must look like sha256:<64 hex chars>."
  }
}

variable "db_password" {
  description = "The password for the database user"
  type        = string
  sensitive   = true
}

variable "keycloak_admin" {
  description = "Username of the bootstrap admin, created on first start only"
  type        = string
  default     = "admin"
}

variable "keycloak_admin_password" {
  description = "Password of the bootstrap admin, applied on first start only"
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

variable "global_address_name" {
  description = "Name of the reserved global static IP used by the forwarding rules"
  type        = string
}

variable "forwarding_rule_ip_address" {
  description = "IP to reserve for the load balancer; leave null to let GCP allocate one"
  type        = string
  default     = null
}

variable "backend_service_name" {
  description = "Name of the backend service and of its serverless NEG"
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
  description = "Public hostname for Keycloak (e.g., keycloak.example.com)"
  type        = string
}

variable "keycloak_log_level" {
  description = "Keycloak log level (e.g., DEBUG, INFO, WARN, ERROR)"
  type        = string
  default     = "INFO"
}

variable "keycloak_admin_header_value" {
  description = "Value of the keycloak-kong request header required to reach /admin through the load balancer"
  type        = string
  sensitive   = true
}
