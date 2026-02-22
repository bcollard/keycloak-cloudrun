# Refactored load balancer configuration using variables for maintainability

# URL Map Resource
resource "google_compute_url_map" "main" {
  name        = var.url_map_name
  description = null
  project     = var.gcp_project

  default_url_redirect {
    host_redirect          = "google.com"
    https_redirect         = true
    path_redirect          = null
    prefix_redirect        = "/"
    redirect_response_code = "MOVED_PERMANENTLY_DEFAULT"
    strip_query            = true
  }

  host_rule {
    description  = null
    hosts        = [var.keycloak_hostname]
    path_matcher = "path-matcher-1"
  }

  path_matcher {
    default_service = null
    description     = null
    name            = "path-matcher-1"
    default_url_redirect {
      host_redirect          = "google.com"
      https_redirect         = true
      path_redirect          = "/"
      prefix_redirect        = null
      redirect_response_code = "FOUND"
      strip_query            = true
    }
    route_rules {
      priority = 1
      service  = null
      match_rules {
        full_path_match     = null
        ignore_case         = false
        path_template_match = null
        prefix_match        = "/admin"
        regex_match         = null
        header_matches {
          exact_match   = var.keycloak_admin_header_value
          header_name   = "keycloak-kong"
          invert_match  = false
          prefix_match  = null
          present_match = false
          regex_match   = null
          suffix_match  = null
        }
      }
      match_rules {
        full_path_match     = null
        ignore_case         = false
        path_template_match = null
        prefix_match        = "/metrics"
        regex_match         = null
        header_matches {
          exact_match   = var.keycloak_admin_header_value
          header_name   = "keycloak-kong"
          invert_match  = false
          prefix_match  = null
          present_match = false
          regex_match   = null
          suffix_match  = null
        }
      }
      match_rules {
        full_path_match     = null
        ignore_case         = false
        path_template_match = null
        prefix_match        = "/health"
        regex_match         = null
        header_matches {
          exact_match   = var.keycloak_admin_header_value
          header_name   = "keycloak-kong"
          invert_match  = false
          prefix_match  = null
          present_match = false
          regex_match   = null
          suffix_match  = null
        }
      }
      match_rules {
        full_path_match     = null
        ignore_case         = false
        path_template_match = null
        prefix_match        = "/realms/"
        regex_match         = null
      }
      match_rules {
        full_path_match     = null
        ignore_case         = false
        path_template_match = null
        prefix_match        = "/.well-known/"
        regex_match         = null
      }
      match_rules {
        full_path_match     = null
        ignore_case         = false
        path_template_match = null
        prefix_match        = "/resources/"
        regex_match         = null
      }
      match_rules {
        full_path_match     = null
        ignore_case         = false
        path_template_match = null
        prefix_match        = "/js/"
        regex_match         = null
      }
      route_action {
        weighted_backend_services {
          backend_service = google_compute_backend_service.main.self_link
          weight          = 100
        }
      }
    }
  }
}

# Target HTTPS Proxy Resource
resource "google_compute_target_https_proxy" "main" {
  name                             = var.target_https_proxy_name
  project                          = var.gcp_project
  url_map                          = google_compute_url_map.main.self_link
  ssl_certificates                 = [google_compute_ssl_certificate.main.self_link]
  description                      = null
  certificate_map                  = null
  proxy_bind                       = false
  quic_override                    = "NONE"
  server_tls_policy                = null
  ssl_policy                       = null
  tls_early_data                   = "DISABLED"
  http_keep_alive_timeout_sec      = 0
}

# SSL Certificate Resource
resource "google_compute_ssl_certificate" "main" {
  name        = var.ssl_certificate_name
  project     = var.gcp_project
  certificate = file(var.ssl_certificate_path)
  private_key = file(var.ssl_certificate_key_path)
  description = null

  lifecycle {
    ignore_changes  = [certificate, private_key]
    prevent_destroy = true
  }
}

# Backend Service Resource
resource "google_compute_backend_service" "main" {
  name                              = var.backend_service_name
  project                           = var.gcp_project
  description                       = null
  protocol                          = "HTTPS"
  port_name                         = "http"
  # timeout_sec is not supported for serverless backends (Cloud Run)
  connection_draining_timeout_sec   = 0
  enable_cdn                        = false
  load_balancing_scheme             = "EXTERNAL_MANAGED"
  locality_lb_policy                = "ROUND_ROBIN"
  session_affinity                  = "NONE"
  affinity_cookie_ttl_sec           = 0
  compression_mode                  = null
  custom_request_headers            = []
  custom_response_headers           = []
  edge_security_policy              = null
  external_managed_migration_state  = null
  external_managed_migration_testing_percentage = 0
  ip_address_selection_policy       = null
  security_policy                   = null
  service_lb_policy                 = null

  backend {
    group                        = "https://www.googleapis.com/compute/v1/projects/${var.gcp_project}/regions/${var.gcp_region}/networkEndpointGroups/${var.backend_service_name}"
    balancing_mode               = "UTILIZATION"
    capacity_scaler              = 1
    description                  = null
    max_connections              = 0
    max_connections_per_endpoint = 0
    max_connections_per_instance = 0
    max_rate                     = 0
    max_rate_per_endpoint        = 0
    max_rate_per_instance        = 0
    max_utilization              = 0
    preference                   = null
  }

  iap {
    enabled              = false
    oauth2_client_id     = null
    oauth2_client_secret = null
  }

  log_config {
    enable          = true
    sample_rate     = 1
    optional_fields = []
    optional_mode   = "EXCLUDE_ALL_OPTIONAL"
  }
}

# Global Forwarding Rule Resource
resource "google_compute_global_forwarding_rule" "main" {
  name                    = var.forwarding_rule_name
  project                 = var.gcp_project
  ip_address              = var.forwarding_rule_ip_address
  target                  = google_compute_target_https_proxy.main.self_link
  port_range              = "443-443"
  ip_protocol             = "TCP"
  description             = null
  labels                  = {}
  network_tier            = "PREMIUM"
  load_balancing_scheme   = "EXTERNAL_MANAGED"
  ip_version              = null
  no_automate_dns_zone    = null
  source_ip_ranges        = []
  external_managed_backend_bucket_migration_state              = null
  external_managed_backend_bucket_migration_testing_percentage = 0
}

# Outputs
output "url_map_self_link" {
  description = "Self link of the URL map"
  value       = google_compute_url_map.main.self_link
}

output "target_https_proxy_self_link" {
  description = "Self link of the target HTTPS proxy"
  value       = google_compute_target_https_proxy.main.self_link
}

output "backend_service_self_link" {
  description = "Self link of the backend service"
  value       = google_compute_backend_service.main.self_link
}

output "forwarding_rule_ip_address" {
  description = "IP address of the global forwarding rule"
  value       = google_compute_global_forwarding_rule.main.ip_address
}
