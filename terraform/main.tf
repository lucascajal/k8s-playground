resource "random_password" "k8s_tunnel_secret" {
  length  = 64
  special = false
}
resource "cloudflare_zero_trust_tunnel_cloudflared" "k8s_tunnel" {
  account_id    = var.cloudflare_account_id
  name          = "k8s-tunnel-tf"
  config_src    = "local"
  tunnel_secret = random_password.k8s_tunnel_secret.result
}

resource "cloudflare_dns_record" "k8s_tunnel_base" {
  type    = "CNAME"
  name    = "@"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.k8s_tunnel.id}.cfargotunnel.com"
  ttl     = 1 # If set to 1, the DNS record will be set to "automatic" TTL
  proxied = true
  comment = "K8s Tunnel base domain"
  zone_id = var.cloudflare_zone_id
}

resource "cloudflare_dns_record" "k8s_tunnel_subdomain_wildcard" {
  type    = "CNAME"
  name    = "*"
  content = "${cloudflare_zero_trust_tunnel_cloudflared.k8s_tunnel.id}.cfargotunnel.com"
  ttl     = 1 # If set to 1, the DNS record will be set to "automatic" TTL
  proxied = true
  comment = "K8s Tunnel wildcard subdomain"
  zone_id = var.cloudflare_zone_id
}