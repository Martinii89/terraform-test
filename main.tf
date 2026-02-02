# Safeguard: Validate that the rendered environment folder exists
resource "null_resource" "validate_rendered_environment" {
  provisioner "local-exec" {
    command     = <<-EOT
      $rendered_path = Join-Path -Path "${path.module}" -ChildPath "rendered\${var.environment}"
      if (-Not (Test-Path $rendered_path -PathType Container)) {
        throw "Rendered environment folder not found: $rendered_path. Available environments: dev, staging, production"
      }
    EOT
    interpreter = ["powershell", "-Command"]
  }
}

# Create SSH key for droplet access
resource "digitalocean_ssh_key" "main" {
  name       = "${var.environment}-key"
  public_key = file("${path.module}/ssh/id_rsa.pub")
  depends_on = [null_resource.validate_rendered_environment]

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

  user_data = templatefile("${path.module}/templates/cloud-init.yaml", {
    CF_API_TOKEN = var.cloudflare_api_token
    GIT_REPO_URL = var.git_repo_url
    ENVIRONMENT  = var.environment
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Copy origin certificate files to the droplet
resource "null_resource" "copy_certificates" {
  triggers = {
    droplet_id = digitalocean_droplet.web.id
  }

  # Wait for cloud-init to complete and create the nginx directory
  provisioner "remote-exec" {
    inline = [
      "while [ ! -d /opt/app/nginx ]; do echo 'Waiting for /opt/app/nginx...'; sleep 5; done",
      "echo 'Directory ready'"
    ]

    connection {
      type        = "ssh"
      user        = "root"
      private_key = file("${path.module}/ssh/id_rsa")
      host        = digitalocean_droplet.web.ipv4_address
      timeout     = "5m"
    }
  }

  provisioner "file" {
    source      = "${path.module}/rendered/${var.environment}/nginx/origin-cert.pem"
    destination = "/opt/app/nginx/sites/origin-cert.pem"

    connection {
      type        = "ssh"
      user        = "root"
      private_key = file("${path.module}/ssh/id_rsa")
      host        = digitalocean_droplet.web.ipv4_address
    }
  }

  provisioner "file" {
    source      = "${path.module}/rendered/${var.environment}/nginx/origin-key.pem"
    destination = "/opt/app/nginx/sites/origin-key.pem"

    connection {
      type        = "ssh"
      user        = "root"
      private_key = file("${path.module}/ssh/id_rsa")
      host        = digitalocean_droplet.web.ipv4_address
    }
  }
}


# Create ACME account
# resource "acme_registration" "main" {}

# # Create certificate with Cloudflare DNS validation
# resource "acme_certificate" "main" {
#   account_key_pem           = acme_registration.main.account_key_pem
#   common_name               = var.domain_name
#   subject_alternative_names = ["*.${var.domain_name}"]
#   depends_on                = [acme_registration.main]

#   dns_challenge {
#     provider = "cloudflare"

#     config = {
#       CLOUDFLARE_DNS_API_TOKEN = var.cloudflare_api_token
#       CLOUDFLARE_ZONE_ID       = var.cloudflare_zone_id
#     }
#   }
# }

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
# Create TLS certificate request for Cloudflare origin certificate
resource "tls_private_key" "origin" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_cert_request" "origin" {
  private_key_pem = tls_private_key.origin.private_key_pem

  subject {
    common_name  = var.domain_name
    organization = "Terraform IaC"
  }
}

# Create Cloudflare origin certificate (for origin-to-Cloudflare encryption)
resource "cloudflare_origin_ca_certificate" "api" {
  csr                = tls_cert_request.origin.cert_request_pem
  hostnames          = [var.domain_name]
  request_type       = "origin-rsa"
  requested_validity = 365
}

# Local files to store certificate and key for use in the droplet
resource "local_sensitive_file" "origin_cert" {
  content  = cloudflare_origin_ca_certificate.api.certificate
  filename = "${path.module}/rendered/${var.environment}/nginx/origin-cert.pem"
}

resource "local_sensitive_file" "origin_key" {
  content  = tls_private_key.origin.private_key_pem
  filename = "${path.module}/rendered/${var.environment}/nginx/origin-key.pem"
}
