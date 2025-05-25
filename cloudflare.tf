provider "cloudflare" {
  api_token = var.cloudflare_token
}

data "cloudflare_zone" "this" {
  filter = {
    name = var.cloudflare_zone
  }
}

resource "cloudflare_dns_record" "load_balancer_ipv4_id" {
  zone_id = data.cloudflare_zone.this.zone_id
  name    = local.issuer_fqdn
  content = google_compute_global_forwarding_rule.ipv4.ip_address
  type    = "A"
  ttl     = 3600
  comment = "Pocket ID GCP load balancer"
}

resource "cloudflare_dns_record" "load_balancer_ipv6_id" {
  zone_id = data.cloudflare_zone.this.zone_id
  name    = local.issuer_fqdn
  content = google_compute_global_forwarding_rule.ipv6.ip_address
  type    = "AAAA"
  ttl     = 3600
  comment = "Pocket ID GCP load balancer"
}

resource "cloudflare_dns_record" "load_balancer_ipv4_account" {
  zone_id = data.cloudflare_zone.this.zone_id
  name    = local.account_fqdn
  content = google_compute_global_forwarding_rule.ipv4.ip_address
  type    = "A"
  ttl     = 3600
  comment = "Pocket ID GCP load balancer"
}

resource "cloudflare_dns_record" "load_balancer_ipv6_account" {
  zone_id = data.cloudflare_zone.this.zone_id
  name    = local.account_fqdn
  content = google_compute_global_forwarding_rule.ipv6.ip_address
  type    = "AAAA"
  ttl     = 3600
  comment = "Pocket ID GCP load balancer"
}
