output "loadbalancer_ip" {
  description = "Load Balancer IP address"
  value       = digitalocean_loadbalancer.main.ip
}

output "loadbalancer_id" {
  description = "Load Balancer ID"
  value       = digitalocean_loadbalancer.main.id
}

output "droplet_id" {
  description = "Web server droplet ID"
  value       = digitalocean_droplet.web.id
}

output "droplet_ipv4" {
  description = "Web server droplet IPv4 address"
  value       = digitalocean_droplet.web.ipv4_address
}

output "certificate_id" {
  description = "DigitalOcean Certificate ID"
  value       = digitalocean_certificate.main.id
}

output "certificate_name" {
  description = "DigitalOcean Certificate Name"
  value       = digitalocean_certificate.main.name
}

output "domain_name" {
  description = "Domain name"
  value       = var.domain_name
}

output "cloudflare_dns_record" {
  description = "Cloudflare DNS record details"
  value = {
    name    = cloudflare_record.loadbalancer.name
    type    = cloudflare_record.loadbalancer.type
    content = cloudflare_record.loadbalancer.content
  }
}
