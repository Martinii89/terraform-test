# Terraform Infrastructure as Code - DigitalOcean & Cloudflare

This repository contains Terraform configuration and deployment scripts to provision containerized infrastructure on DigitalOcean with DNS management via Cloudflare. It supports multiple environments (dev, staging, production) with templated configuration rendering and automated SSL certificate management.

## Architecture

- **Web Server**: Ubuntu droplet running Docker and docker-compose
- **Container Orchestration**: Docker Compose for service management
- **Reverse Proxy**: Nginx with automatic SSL certificate management via Let's Encrypt + Cloudflare DNS validation
- **DNS**: Cloudflare DNS records pointing to the droplet IP
- **SSL/TLS**: Let's Encrypt certificate with ACME provider and automatic renewal

## Key Features

- **Multi-environment support**: dev, staging, and production configurations
- **Template-based rendering**: Configuration files templated and rendered per environment using PowerShell script
- **Automated provisioning**: Cloud-init scripts handle Docker, docker-compose, and application deployment
- **Infrastructure as code**: All resources managed via Terraform (DigitalOcean, Cloudflare, ACME, TLS providers)
- **Flexible SSL/TLS**: Support for both Let's Encrypt staging (testing) and production environments

## Prerequisites

1. **Terraform** >= 1.0 installed
2. **DigitalOcean** account with API token
3. **Cloudflare** account with API token and zone ID
4. **PowerShell** (for template rendering on Windows)
5. **SSH Key** for droplet access

## Project Structure

```
├── main.tf                 # Primary Terraform configuration (droplet, SSH key, cloud-init)
├── providers.tf            # Provider configuration (DigitalOcean, Cloudflare, ACME, TLS)
├── variables.tf            # Variable definitions for configuration
├── outputs.tf              # Output values (droplet ID, IP, DNS records)
├── scripts/
│   ├── render.ps1         # PowerShell script to render templates per environment
│   ├── plan-staging.bat   # Batch script for planning staging infrastructure
│   └── apply-staging.bat  # Batch script for applying staging infrastructure
├── templates/
│   ├── cloud-init.yaml    # Cloud-init script template for droplet initialization
│   └── infra/
│       ├── docker-compose.yaml.tpl
│       └── nginx/
│           ├── nginx.conf
│           └── sites/
│               └── api.conf.tpl
├── rendered/              # Generated configuration files per environment
│   ├── dev/
│   ├── staging/
│   └── production/
└── ssh/                   # SSH keys for droplet access (git-ignored)
```

## Setup Instructions

### 1. Generate SSH Key

Create an SSH key pair for droplet access:

```bash
mkdir -p ssh
ssh-keygen -t rsa -b 4096 -f ssh/id_rsa -N "" -C "terraform@droplet"
```

### 2. Configure Variables

Copy the example variables file and update with your values:

```bash
cp terraform.tfvars.example terraform.tfvars
```

Edit `terraform.tfvars` and add:

- `digitalocean_token`: Your DigitalOcean API token
- `cloudflare_api_token`: Your Cloudflare API token with DNS edit permissions
- `cloudflare_zone_id`: Your Cloudflare zone ID
- `domain_name`: Your domain (e.g., example.com)
- `letsencrypt_email`: Email for Let's Encrypt certificate notifications
- `git_repo_url`: URL of this repository for cloud-init to clone
- `environment`: Target environment (dev, staging, or production)
- `region`: DigitalOcean region (default: nyc3)

### 3. Render Configuration Templates

Before applying Terraform, render the configuration templates for your target environment:

```powershell
.\scripts\render.ps1 staging terraform.example.com admin@example.com
```

This generates environment-specific docker-compose and nginx configurations in the `rendered/<environment>/` directory.

### 4. Initialize Terraform

```bash
terraform init
```

### 5. Plan and Apply

```bash
terraform plan -var-file=terraform.tfvars -out=tfplan
terraform apply tfplan
```

## Workflow

### Rendered Manifest Pattern

This project uses a **rendered manifest pattern** similar to [Kargo](https://kargo.akuity.io/), where templates are rendered to concrete configuration files and committed to version control. This approach provides:

- **Auditability**: Every deployed configuration is tracked in Git history
- **Environment parity**: Consistent templates ensure environments differ only in their rendered output
- **Declarative state**: Rendered files serve as the source of truth for deployed configurations
- **Change visibility**: Git diffs clearly show what configuration changes are being deployed

**Flow:**

```
templates/infra/ (source of truth)
    ↓ [render.ps1]
rendered/<environment>/ (committed to Git)
    ↓ [cloud-init pulls]
/opt/app (deployed on droplet)
```

### Template Rendering

The `render.ps1` script processes templates in `templates/infra/` and generates environment-specific configuration files:

- Substitutes environment variables (`$DOMAIN_NAME`, `$LETSENCRYPT_EMAIL`)
- Outputs to `rendered/<environment>/` directory
- `.tpl` template files are rendered; static files are copied as-is
- Rendered files are committed to version control for auditability

Usage:

```powershell
.\scripts\render.ps1 <environment> <domain_name> <letsencrypt_email>
```

**Example workflow:**

```powershell
# 1. Render templates for staging environment
.\scripts\render.ps1 staging api.example.com admin@example.com

# 2. Review changes
git diff rendered/staging/

# 3. Commit rendered configuration
git add rendered/staging/
git commit -m "Update staging configuration for new domain"

# 4. Deploy infrastructure
terraform apply -var-file=terraform.tfvars
```

### Terraform Workflow

1. **Validation**: Terraform validates that the rendered environment folder exists
2. **SSH Key Creation**: Registers the public key with DigitalOcean
3. **Droplet Provisioning**: Creates Ubuntu droplet with cloud-init user data
4. **DNS Configuration**: Creates Cloudflare DNS records pointing to the droplet
5. **Cloud-init Execution**: Droplet automatically pulls the rendered configs and starts services

### Cloud-init Initialization

When the droplet boots, cloud-init:

1. Installs Docker and docker-compose
2. Clones this repository to `/opt/infra`
3. Copies environment-specific rendered configs to `/opt/app`
4. Creates Certbot DNS credentials for Cloudflare
5. Starts the docker-compose stack with nginx and application services

## Environment Variables in Cloud-init

The cloud-init template supports:

- `GIT_REPO_URL`: Repository URL to clone
- `ENVIRONMENT`: Target environment (dev, staging, production)
- `CF_API_TOKEN`: Cloudflare API token for DNS validation and certificate renewal

## Terraform Outputs

After `terraform apply`, retrieve outputs with:

```bash
terraform output              # Display all outputs
terraform output droplet_id   # Droplet ID
terraform output droplet_ipv4 # Droplet IP address
terraform output domain_name  # Domain name
terraform output cloudflare_dns_record # DNS record details
```

## Customization

### Change DigitalOcean Region

Modify `region` in `terraform.tfvars`:

- nyc3 (New York)
- sfo3 (San Francisco)
- lon1 (London)
- tor1 (Toronto)
- sgp1 (Singapore)

### Change Droplet Size

Modify `droplet_size` in `terraform.tfvars`:

- `s-1vcpu-512mb-10gb` (512MB) - smallest
- `s-1vcpu-1gb-25gb` (1GB)
- `s-2vcpu-2gb-60gb` (2GB)
- See [DigitalOcean docs](https://docs.digitalocean.com/products/droplets/concepts/compute-resources/) for full list

### Enable Let's Encrypt Production

By default, `acme_staging` is `true` (uses staging environment for testing). To use production certificates:

```hcl
acme_staging = false
```

## Cost Considerations

**Estimated monthly cost** (nyc3 region):

- Droplet (s-1vcpu-512mb-10gb): $4/month
- **Total: ~$4/month**

## Troubleshooting

### Rendered Environment Folder Not Found

Ensure you've run the render.ps1 script for your target environment:

```powershell
.\scripts\render.ps1 staging yourdomain.com your@email.com
```

This creates the required `rendered/staging/` directory structure.

### Certificate Not Issuing

If the Let's Encrypt certificate fails:

1. Verify `cloudflare_api_token` has proper DNS edit permissions
2. Verify `cloudflare_zone_id` is correct
3. For staging mode, certificates won't be trusted—switch `acme_staging = false` for production
4. Check droplet logs after it boots: `ssh root@<droplet-ip> journalctl -u docker`

### DNS Not Resolving

1. Verify zone ID is correct in Cloudflare
2. Check nameservers are pointing to Cloudflare
3. Allow DNS propagation time (up to 24 hours)
4. Test with: `nslookup yourdomain.com`

### Droplet Boot Issues

SSH into the droplet and check cloud-init logs:

```bash
ssh -i ssh/id_rsa root@<droplet-ip>
tail -f /var/log/cloud-init-output.log
docker ps  # Check running containers
```

### Docker Compose Failed to Start

Check the rendered configuration is correct:

```bash
cat rendered/<environment>/docker-compose.yaml
```

And verify environment variables are set in the droplet:

```bash
ssh -i ssh/id_rsa root@<droplet-ip> env | grep CF_API_TOKEN
```

```bash
ssh -i ssh/id_rsa root@<droplet-ip>
```

## Automatic Certificate Renewal - Detailed Guide

### How It Works

The ACME provider checks certificate expiration every time you run `terraform apply`. If a certificate is expiring within 30 days, it automatically renews it via Let's Encrypt.

### Setting up Cronjob on Linux/macOS

Add a weekly renewal check:

```bash
# Add to crontab
crontab -e

# Add this line (runs every Sunday at midnight)
0 0 * * 0 /path/to/project/scripts/renew-certificate.sh
```

Or daily:

```bash
0 0 * * * /path/to/project/scripts/renew-certificate.sh
```

### Setting up Scheduled Task on Windows

Use Task Scheduler to run the renewal script with PowerShell:

```powershell
# Create scheduled task (run as administrator)
$action = New-ScheduledTaskAction -Execute "pwsh.exe" -Argument "-File `"C:\Path\To\Project\scripts\renew-certificate.ps1`""
$trigger = New-ScheduledTaskTrigger -Weekly -DaysOfWeek Sunday -At 12:00AM
Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "TerraformCertificateRenewal" -Description "Renew Let's Encrypt certificates via Terraform"
```

### Using GitHub Actions for Renewal (CI/CD)

Add to `.github/workflows/renew-certs.yml`:

```yaml
name: Renew Certificates

on:
  schedule:
    - cron: "0 0 * * 0" # Weekly Sunday
  workflow_dispatch: # Manual trigger

jobs:
  renew:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: hashicorp/setup-terraform@v2
      - name: Renew certificates
        run: terraform apply -auto-approve -var-file="terraform.tfvars"
        env:
          TF_VAR_digitalocean_token: ${{ secrets.DIGITALOCEAN_TOKEN }}
          TF_VAR_cloudflare_api_token: ${{ secrets.CLOUDFLARE_API_TOKEN }}
          TF_VAR_cloudflare_zone_id: ${{ secrets.CLOUDFLARE_ZONE_ID }}
```

## Cleanup

To destroy all infrastructure:

```bash
terraform destroy
```

## Additional Resources

- [DigitalOcean Terraform Provider](https://registry.terraform.io/providers/digitalocean/digitalocean/latest/docs)
- [Cloudflare Terraform Provider](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs)
- [Terraform Documentation](https://www.terraform.io/docs)

## Security Best Practices

1. Never commit `terraform.tfvars` (it contains sensitive tokens)
2. Use Terraform Cloud/Enterprise for state management
3. Enable MFA on DigitalOcean and Cloudflare accounts
4. Rotate API tokens regularly
5. Keep SSH private keys secure
6. Consider using Terraform variables file: `terraform.tfvars.json` with encryption

## Support

For issues with:

- **Terraform**: Check official documentation
- **DigitalOcean**: Visit https://www.digitalocean.com/support
- **Cloudflare**: Visit https://support.cloudflare.com
