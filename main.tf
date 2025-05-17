terraform {
  required_version = ">=1.9"
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = ">=3.7.2"
    }
    google = {
      source  = "hashicorp/google"
      version = ">=6.35.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }
}

variable "gcp_billing_account" {
  type     = string
  nullable = false
}

variable "region" {
  type     = string
  nullable = false
  default  = "europe-west4"
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
  type      = string
  nullable  = false
  ephemeral = true
  sensitive = true
}

variable "cloudflare_zone" {
  type     = string
  nullable = false
}

variable "schedule_region" {
  type        = string
  nullable    = false
  description = "Must be a valid region for scheduling"
  default     = "europe-west3"
}

variable "backblaze_key_id" {
  type      = string
  nullable  = false
  ephemeral = true
  sensitive = true
}

variable "backblaze_key" {
  type      = string
  nullable  = false
  ephemeral = true
  sensitive = true
}

variable "backblaze_bucket" {
  type     = string
  nullable = false
}

variable "backblaze_repository_password" {
  type      = string
  nullable  = false
  ephemeral = true
  sensitive = true
}

variable "webfinger_acct" {
  type        = string
  description = "Account resource to serve .well-known/webfinger for"
}

variable "pocket-id_env" {
  type        = map(string)
  description = "Additional env variables for pocket-id"
  default     = {}
}
