terraform {
  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5"
    }
    random = {
      source = "hashicorp/random"
    }
    bitwarden = {
      source  = "maxlaverse/bitwarden"
      version = ">= 0.13.6"
    }
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

provider "bitwarden" {
  access_token          = var.bitwarden_token
  client_implementation = "embedded"
}
