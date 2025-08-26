terraform {
  required_version = ">=1.9"
  required_providers {
    random = {
      source  = "hashicorp/random"
      version = ">=3.7.2"
    }
    google = {
      source  = "hashicorp/google"
      version = "~> 6.36"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 7.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
  }
}
