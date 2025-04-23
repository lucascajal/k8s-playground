# Cloudflare variables
variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID"
  type        = string
  sensitive   = true
}
variable "cloudflare_account_id" {
  description = "Cloudflare account ID"
  type        = string
  sensitive   = true
}
variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  sensitive   = true
}
variable "cloudflare_domain" {
  description = "Base domain name"
  type        = string
  default     = "lucascajal.com"
}
variable "cloudflare_cert_manager_api_token" {
  description = "Cloudflare API token for cert-manager"
  type        = string
  sensitive   = true
}

# Bitwarden variables
variable "bitwarden_token" {
  description = "Bitwarden access token"
  type        = string
  sensitive   = true
}

# Auth0 variables
variable "auth0_client_id" {
  description = "Auth0 client ID"
  type        = string
  sensitive   = true
}
variable "auth0_client_secret" {
  description = "Auth0 client secret"
  type        = string
  sensitive   = true
}
variable "auth0_cookie_secret" {
  description = "Auth0 cookie secret"
  type        = string
  sensitive   = true
}

# Container Registry variables
variable "container_registry_creds" {
  description = "Container registry dockerconfig json"
  type        = any
  sensitive   = true
}