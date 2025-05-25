variable "gcp_billing_account" {
  type        = string
  description = "Billing account to attach the new project to"
  nullable    = false
}

variable "region" {
  type        = string
  nullable    = false
  description = "Region to provision resources in"
  default     = "europe-west4"
}

variable "issuer_subdomain" {
  type        = string
  description = "Subdomain where the issuer is running"
  nullable    = false
}

variable "account_subdomain" {
  type        = string
  description = "Subdomain that user accounts belong to"
  nullable    = false
}

locals {
  issuer_fqdn  = join(".", compact([var.issuer_subdomain, var.cloudflare_zone]))
  account_fqdn = join(".", compact([var.account_subdomain, var.cloudflare_zone]))
}

variable "cloudflare_token" {
  type        = string
  description = "Authentication for cloudflare API"
  nullable    = false
  ephemeral   = true
  sensitive   = true
}

variable "cloudflare_zone" {
  type        = string
  description = "Cloudflare DNS zone"
  nullable    = false
}

variable "schedule_region" {
  type        = string
  description = "Must be a valid region for scheduling"
  nullable    = false
  default     = "europe-west3"
}

variable "backblaze_key_id" {
  type        = string
  description = "S3-like access key id"
  nullable    = false
  ephemeral   = true
  sensitive   = true
}

variable "backblaze_key" {
  type        = string
  description = "S3-like secret access key"
  nullable    = false
  ephemeral   = true
  sensitive   = true
}

variable "backblaze_bucket" {
  type        = string
  description = "URI for backblaze bucket"
  nullable    = false
}

variable "backblaze_repository_password" {
  type        = string
  description = "Password for encrypting restic backups"
  nullable    = false
  ephemeral   = true
  sensitive   = true
}

variable "webfinger_acct" {
  type        = string
  description = "Account resource to serve .well-known/webfinger for"
}

variable "additional_env" {
  type        = map(string)
  description = "Additional env variables for pocket-id"
  default     = {}
}
