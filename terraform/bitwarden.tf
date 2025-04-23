resource "bitwarden_project" "bitwarden_project" {
  name = "k8s-cluster-tf"
}

# Bitwarden
resource "bitwarden_secret" "bitwarden_token" {
  key        = "bitwarden-token"
  value      = var.bitwarden_token
  project_id = bitwarden_project.bitwarden_project.id
  note       = "Access token for the Bitwarden API"
}

# Cloudflare
resource "bitwarden_secret" "tunnel_credentials" {
  key = "cloudflared-tunnel-credentials"
  value = jsonencode({
    AccountTag   = var.cloudflare_account_id
    TunnelID     = cloudflare_zero_trust_tunnel_cloudflared.k8s_tunnel.id
    TunnelSecret = random_password.k8s_tunnel_secret.result
  })
  project_id = bitwarden_project.bitwarden_project.id
  note       = "Generated credentials for the k8s tunnel"
}
resource "bitwarden_secret" "cloudflare_account_id" {
  key        = "cloudflare-account-id-terraform"
  value      = var.cloudflare_account_id
  project_id = bitwarden_project.bitwarden_project.id
  note       = "Cloudflare account ID"
}
resource "bitwarden_secret" "cloudflare_zone_id" {
  key        = "cloudflare-zone-id-terraform"
  value      = var.cloudflare_zone_id
  project_id = bitwarden_project.bitwarden_project.id
  note       = "Cloudflare Zone ID"
}
resource "bitwarden_secret" "cloudflare_api_token" {
  key        = "cloudflare-api-token-terraform"
  value      = var.cloudflare_api_token
  project_id = bitwarden_project.bitwarden_project.id
  note       = "Cloudflare API Token"
}
resource "bitwarden_secret" "cloudflare_cert_manager_api_token" {
  key        = "cert-manager-cloudflare-token"
  value      = var.cloudflare_cert_manager_api_token
  project_id = bitwarden_project.bitwarden_project.id
  note       = "Cloudflare API Token"
}

# Auth0
resource "bitwarden_secret" "auth0_client_id" {
  key        = "OIDC-Client-ID"
  value      = var.auth0_client_id
  project_id = bitwarden_project.bitwarden_project.id
  note       = "Auth0 client ID"
}
resource "bitwarden_secret" "auth0_client_secret" {
  key        = "OIDC-Client-Secret"
  value      = var.auth0_client_secret
  project_id = bitwarden_project.bitwarden_project.id
  note       = "Auth0 client secret"
}
resource "bitwarden_secret" "auth0_cookie_secret" {
  key        = "OIDC-Cookie-Secret"
  value      = var.auth0_cookie_secret
  project_id = bitwarden_project.bitwarden_project.id
  note       = "Auth0 cookie secret. Generated with following command:\ndd if=/dev/urandom bs=32 count=1 2>/dev/null | base64 | tr -d -- '\\n' | tr -- '+/' '-_' ; echo"
}

# Container Registry
resource "bitwarden_secret" "container_registry_creds" {
  key        = "container-registry-creds"
  value      = jsonencode(var.container_registry_creds)
  project_id = bitwarden_project.bitwarden_project.id
  note       = "Container registry credentials, as a dockerconfig json"
}