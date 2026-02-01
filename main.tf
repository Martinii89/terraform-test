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

# Create Firewall for the droplet
resource "digitalocean_firewall" "web" {
  name        = "${var.environment}-web-firewall"
  droplet_ids = [digitalocean_droplet.web.id]

  # Allow SSH
  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0"]
  }

  # Allow HTTP
  inbound_rule {
    protocol         = "tcp"
    port_range       = "80"
    source_addresses = ["0.0.0.0/0"]
  }

  # Allow HTTPS
  inbound_rule {
    protocol         = "tcp"
    port_range       = "443"
    source_addresses = ["0.0.0.0/0"]
  }

  # Allow all outbound traffic
  outbound_rule {
    protocol              = "tcp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "1-65535"
    destination_addresses = ["0.0.0.0/0"]
  }
}

# Create DNS record in Cloudflare pointing to the Droplet
resource "cloudflare_record" "droplet" {
  zone_id = var.cloudflare_zone_id
  name    = var.domain_name
  type    = "A"
  content = digitalocean_droplet.web.ipv4_address
  ttl     = var.cloudflare_proxy_main_domain ? 1 : 3600
  proxied = var.cloudflare_proxy_main_domain
}

# Optional: Create a wildcard DNS record for subdomains
resource "cloudflare_record" "wildcard" {
  zone_id = var.cloudflare_zone_id
  name    = "*.${var.domain_name}"
  type    = "A"
  content = digitalocean_droplet.web.ipv4_address
  ttl     = var.cloudflare_proxy_wildcard_domain ? 1 : 3600
  proxied = var.cloudflare_proxy_wildcard_domain
}
