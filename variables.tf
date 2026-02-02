variable "digitalocean_token" {
  description = "DigitalOcean API token"
  type        = string
  sensitive   = true
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token"
  type        = string
  sensitive   = true
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID"
  type        = string
  sensitive   = true
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "staging"
}

variable "region" {
  description = "DigitalOcean region"
  type        = string
  default     = "nyc3"
}

variable "domain_name" {
  description = "Domain name for the load balancer"
  type        = string
}

variable "droplet_name" {
  description = "Name of the droplet"
  type        = string
  default     = "web-server-01"
}

variable "droplet_size" {
  description = "DigitalOcean droplet size slug"
  type        = string
  default     = "s-1vcpu-512mb-10gb" # smallest available
}

variable "droplet_image" {
  description = "DigitalOcean droplet image slug"
  type        = string
  default     = "ubuntu-24-04-x64"
}

variable "letsencrypt_email" {
  description = "Email for Let's Encrypt certificate"
  type        = string
}

variable "acme_staging" {
  description = "Use Let's Encrypt staging environment for testing (true = staging, false = production)"
  type        = bool
  default     = true
}

variable "cloudflare_proxy_main_domain" {
  description = "Proxy main domain DNS record through Cloudflare (true = proxied/orange cloud, false = DNS only/gray cloud)"
  type        = bool
  default     = false
}

variable "cloudflare_proxy_wildcard_domain" {
  description = "Proxy wildcard DNS record through Cloudflare (true = proxied/orange cloud, false = DNS only/gray cloud). Note: Cloudflare free tier may have TLS issues with nested subdomains when proxied."
  type        = bool
  default     = false
}
variable "git_repo_url" {
  description = "Git repository URL to clone for infrastructure"
  type        = string
}
