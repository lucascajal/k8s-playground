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
  access_token = var.bitwarden_token

  # If you have the opportunity, you can try out the embedded client which
  # removes the need for a locally installed Bitwarden CLI. Please note that
  # this feature is still considered experimental and not recommended for
  # production use.
  #
  experimental {
    embedded_client = true
  }
}