# Something is wonky with the project links here that we get
# Invalid value for field 'project': 'projects/pocket-id-773920'. Must be a match of regex '(?:(?:[-a-z0-9]{1,63}\.)*(?:[a-z](?:[-a-z0-9]{0,61}[a-z0-9])?):)?(?:[0-9]{1,19}|(?:[a-z0-9](?:[-a-z0-9]{0,61}[a-z0-9])?))', invalid
# even though the resources are actually created. Leaving out the `projects/`
# seems to work too so call `trimprefix`.
resource "google_compute_backend_service" "this" {
  project               = trimprefix(google_project.this.project_id, "projects/")
  name                  = "pocket-id"
  protocol              = "HTTP"
  load_balancing_scheme = "EXTERNAL_MANAGED"
  backend {
    group = google_compute_region_network_endpoint_group.this.id
  }
}

resource "google_compute_global_forwarding_rule" "ipv4" {
  load_balancing_scheme = "EXTERNAL_MANAGED"
  name                  = "pocket-id-https-ipv4"
  port_range            = "443"
  ip_version            = "IPV4"
  project               = google_project.this.id
  target                = google_compute_target_https_proxy.this.id
}

resource "google_compute_global_forwarding_rule" "ipv6" {
  load_balancing_scheme = "EXTERNAL_MANAGED"
  name                  = "pocket-id-https-ipv6"
  port_range            = "443"
  ip_version            = "IPV6"
  project               = google_project.this.id
  target                = google_compute_target_https_proxy.this.id
}

resource "google_compute_ssl_policy" "this" {
  project         = trimprefix(google_project.this.project_id, "projects/")
  name            = "pocket-id"
  profile         = "RESTRICTED"
  min_tls_version = "TLS_1_2"
}

resource "google_compute_target_https_proxy" "this" {
  project          = trimprefix(google_project.this.project_id, "projects/")
  name             = "pocket-id"
  ssl_certificates = [google_compute_managed_ssl_certificate.issuer.id, google_compute_managed_ssl_certificate.account.id]
  ssl_policy       = google_compute_ssl_policy.this.self_link
  url_map          = google_compute_url_map.this.self_link
  tls_early_data   = "STRICT"
}

resource "google_compute_managed_ssl_certificate" "issuer" {
  project = trimprefix(google_project.this.project_id, "projects/")
  name    = "pocket-id-issuer-managed"
  type    = "MANAGED"

  managed {
    domains = [
      local.issuer_fqdn
    ]
  }
}

resource "google_compute_managed_ssl_certificate" "account" {
  project = google_project.this.project_id
  name    = "pocket-id-account-managed"
  type    = "MANAGED"

  managed {
    domains = [
      local.account_fqdn
    ]
  }
}

locals {
  matches = [
    { resource = urlencode("acct:${var.webfinger_acct}") },
    { resource = urlencode("acct:${var.webfinger_acct}"), rel = urlencode("http://openid.net/specs/connect/1.0/issuer") },
  ]
}

resource "google_compute_url_map" "this" {
  # for default_custom_error_response_policy
  provider        = google-beta
  project         = trimprefix(google_project.this.project_id, "projects/")
  name            = "pocket-id"
  default_service = google_compute_backend_service.this.self_link

  host_rule {
    hosts        = [local.issuer_fqdn]
    path_matcher = "id"
  }

  host_rule {
    hosts        = [local.account_fqdn]
    path_matcher = "webfinger"
  }

  path_matcher {
    name            = "id"
    default_service = google_compute_backend_service.this.self_link

    route_rules {
      priority = 1
      service  = google_compute_backend_bucket.static.id

      dynamic "match_rules" {
        for_each = local.matches
        content {
          full_path_match = "/.well-known/webfinger"
          dynamic "query_parameter_matches" {
            for_each = match_rules.value
            content {
              name        = query_parameter_matches.key
              exact_match = query_parameter_matches.value
            }
          }
        }
      }
    }
  }

  path_matcher {
    name            = "webfinger"
    default_service = google_compute_backend_bucket.static.id

    default_custom_error_response_policy {
      error_response_rule {
        match_response_codes   = ["4xx", "5xx"]
        path                   = "/404.html"
        override_response_code = "404"
      }
      error_service = google_compute_backend_bucket.static.id
    }

    # This is necessary to avoid the "AccessDenied" weird bucket exceptions
    default_route_action {
      url_rewrite {
        path_prefix_rewrite = "/this-doesn't-exist"
      }
    }

    route_rules {
      priority = 1
      service  = google_compute_backend_bucket.static.id

      dynamic "match_rules" {
        for_each = local.matches
        content {
          full_path_match = "/.well-known/webfinger"
          dynamic "query_parameter_matches" {
            for_each = match_rules.value
            content {
              name        = query_parameter_matches.key
              exact_match = query_parameter_matches.value
            }
          }
        }
      }
    }
  }
}

resource "google_compute_region_network_endpoint_group" "this" {
  project               = google_project.this.project_id
  name                  = "pocket-id"
  network_endpoint_type = "SERVERLESS"
  region                = var.region
  cloud_run {
    service = google_cloud_run_v2_service.this.name
  }
}

resource "google_compute_backend_bucket" "static" {
  project     = google_project.this.project_id
  name        = "webfinger"
  bucket_name = google_storage_bucket.static.name
}
