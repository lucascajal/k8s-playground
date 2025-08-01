output "bitwarden_project_id" {
  sensitive = true
  value     = data.bitwarden_project.k8s_cluster_tf.id
}
output "bitwarden_project_name" {
  value = data.bitwarden_project.k8s_cluster_tf.name
}
output "bitwarden_token" {
  sensitive = true
  value     = var.bitwarden_token
}

output "tunnel_id" {
  sensitive = true
  value     = cloudflare_zero_trust_tunnel_cloudflared.k8s_tunnel.id
}

output "tunnel_secret" {
  sensitive = true
  value     = random_password.k8s_tunnel_secret.result
}