output "droplet_id" {
  description = "Web server droplet ID"
  value       = digitalocean_droplet.web.id
}

output "droplet_ipv4" {
  description = "Web server droplet IPv4 address"
  value       = digitalocean_droplet.web.ipv4_address
}

output "domain_name" {
  description = "Domain name"
  value       = var.domain_name
}

output "cloudflare_dns_record" {
  description = "Cloudflare DNS record details"
  value = {
    name    = cloudflare_record.droplet.name
    type    = cloudflare_record.droplet.type
    content = cloudflare_record.droplet.content
  }
}
