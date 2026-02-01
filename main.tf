# Create SSH key for droplet access
resource "digitalocean_ssh_key" "main" {
  name       = "${var.environment}-key"
  public_key = file("${path.module}/ssh/id_rsa.pub")

  lifecycle {
    ignore_changes = [name]
  }
}

# Create a droplet
resource "digitalocean_droplet" "web" {
  image      = var.droplet_image
  name       = var.droplet_name
  region     = var.region
  size       = var.droplet_size
  ssh_keys   = [digitalocean_ssh_key.main.fingerprint]
  monitoring = true

  tags = [var.environment, "web"]

  user_data = file("${path.module}/templates/cloud-init.yaml")

  lifecycle {
    create_before_destroy = true
  }
}


# Create ACME account
resource "acme_registration" "main" {}

# Create certificate with Cloudflare DNS validation
resource "acme_certificate" "main" {
  account_key_pem           = acme_registration.main.account_key_pem
  common_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  depends_on                = [acme_registration.main]

  dns_challenge {
    provider = "cloudflare"

    config = {
      CLOUDFLARE_DNS_API_TOKEN = var.cloudflare_api_token
      CLOUDFLARE_ZONE_ID       = var.cloudflare_zone_id
    }
  }
}

# Upload certificate to DigitalOcean
resource "digitalocean_certificate" "main" {
  name              = "${var.environment}-${replace(var.domain_name, ".", "-")}-cert"
  private_key       = acme_certificate.main.private_key_pem
  leaf_certificate  = acme_certificate.main.certificate_pem
  certificate_chain = acme_certificate.main.issuer_pem

  lifecycle {
    create_before_destroy = true
  }
}

# Create Load Balancer with TLS termination
resource "digitalocean_loadbalancer" "main" {
  name   = "${var.environment}-lb"
  region = var.region

  droplet_ids = [digitalocean_droplet.web.id]

  redirect_http_to_https   = true
  enable_backend_keepalive = true


  forwarding_rule {
    entry_protocol = "http2"
    entry_port     = 443

    target_protocol = "http"
    target_port     = 80

    certificate_name = digitalocean_certificate.main.name
  }

  forwarding_rule {
    entry_protocol = "http3"
    entry_port     = 443

    target_protocol = "http"
    target_port     = 80

    certificate_name = digitalocean_certificate.main.name
  }

  # HTTP traffic redirects to HTTPS at Cloudflare level or browser level
  forwarding_rule {
    entry_protocol = "http"
    entry_port     = 80

    target_protocol = "http"
    target_port     = 80
  }

  healthcheck {
    port     = 80
    protocol = "http"
    path     = "/"
  }

  sticky_sessions {
    type = "none"
  }
}

# Create DNS record in Cloudflare pointing to the Load Balancer
resource "cloudflare_record" "loadbalancer" {
  zone_id = var.cloudflare_zone_id
  name    = var.domain_name
  type    = "A"
  content = digitalocean_loadbalancer.main.ip
  ttl     = var.cloudflare_proxy_main_domain ? 1 : 3600
  proxied = var.cloudflare_proxy_main_domain
}

# Optional: Create a wildcard DNS record for subdomains
resource "cloudflare_record" "wildcard" {
  zone_id = var.cloudflare_zone_id
  name    = "*.${var.domain_name}"
  type    = "A"
  content = digitalocean_loadbalancer.main.ip
  ttl     = var.cloudflare_proxy_wildcard_domain ? 1 : 3600
  proxied = var.cloudflare_proxy_wildcard_domain
}
