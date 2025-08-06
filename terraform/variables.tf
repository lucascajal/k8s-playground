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
variable "bitwarden_project_id" {
  description = "Bitwarden project"
  type        = string
  sensitive   = true
}

# OIDC vars
variable "auth0_oidc_client_id" {
  description = "Auth0 client ID for Kubernetes dashboard"
  type        = string
  sensitive   = true
}
variable "auth0_oidc_client_secret" {
  description = "Auth0 client secret for Kubernetes dashboard"
  type        = string
  sensitive   = true
}
variable "auth0_oidc_cookie_secret" {
  description = "Auth0 cookie secret for Kubernetes dashboard"
  type        = string
  sensitive   = true
}

# Container Registry variables
variable "registry_url" {
  type = string
}
variable "registry_username" {
  type      = string
  sensitive = true
}
variable "registry_password" {
  type      = string
  sensitive = true
}

# ArgoCD vars
variable "auth0_argocd_client_id" {
  description = "Auth0 client ID for ArgoCD"
  type        = string
  sensitive   = true
}
variable "auth0_argocd_client_secret" {
  description = "Auth0 client secret for ArgoCD"
  type        = string
  sensitive   = true
}
variable "argocd_github_repos_base_url" {
  description = "Github repositories URL prefix for private repo read template"
  type        = string
  sensitive   = true
}
variable "argocd_github_repos_read_token" {
  description = "Github repositories token for private repo read template"
  type        = string
  sensitive   = true
}

# Prometheus & Grafana vars
variable "auth0_grafana_client_id" {
  description = "Auth0 client ID for Grafana"
  type        = string
  sensitive   = true
}
variable "auth0_grafana_client_secret" {
  description = "Auth0 client secret for Grafana"
  type        = string
  sensitive   = true
}