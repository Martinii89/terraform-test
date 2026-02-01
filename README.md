# Terraform Infrastructure as Code - Digital Ocean & Cloudflare

This repository contains Terraform configuration to provision infrastructure on DigitalOcean with DNS management via Cloudflare.

## Architecture

- **Load Balancer**: DigitalOcean Load Balancer with TLS termination (Let's Encrypt certificate)
- **Web Server**: Ubuntu droplet (smallest available: 512MB RAM, 1vCPU, 10GB SSD)
- **DNS**: Cloudflare DNS records pointing to the load balancer IP
- **SSL/TLS**: Let's Encrypt certificate with ACME provider + automatic renewal via Cloudflare DNS validation

## Prerequisites

1. **Terraform** >= 1.0 installed
2. **DigitalOcean** account with API token
3. **Cloudflare** account with API token and domain
4. **SSH Key** for droplet access

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
- `cloudflare_api_token`: Your Cloudflare API token
- `cloudflare_zone_id`: Your Cloudflare zone ID
- `domain_name`: Your domain (e.g., example.com)
- `letsencrypt_email`: Email for Let's Encrypt notifications

### 3. Initialize Terraform

```bash
terraform init
```

### 4. Review the Plan

```bash
terraform plan
```

### 5. Apply Configuration

```bash
terraform apply
```

### 6. Set up Automatic Certificate Renewal

The ACME provider automatically renews certificates, but Terraform needs to run periodically to check. Set up a cronjob:

**Copy the environment file:**

```bash
cp .env.example .env
# Edit .env and add your API tokens (or leave empty if using terraform.tfvars)
```

**Add a cronjob to run weekly (e.g., Sunday at midnight):**

```bash
# Make the script executable
chmod +x scripts/renew-certificate.sh

# Add to crontab (runs every Sunday at midnight)
0 0 * * 0 /path/to/your/project/scripts/renew-certificate.sh
```

**Or use a daily run for more frequent checks:**

```bash
0 0 * * * /path/to/your/project/scripts/renew-certificate.sh
```

The script will:

- Check certificate expiration (ACME provider does this automatically)
- Renew if expiring within 30 days
- Log all activity to `terraform-renewal.log`

### 7. Verify Infrastructure

Once applied, you can:

1. Access outputs with: `terraform output`
2. Verify DNS propagation: `dig example.com`
3. Check certificate: `curl -I https://example.com`

## File Structure

```
.
├── providers.tf          # Provider configuration (ACME, TLS, DigitalOcean, Cloudflare)
├── variables.tf          # Variable definitions
├── main.tf              # Main infrastructure resources
├── outputs.tf           # Output values
├── terraform.tfvars.example  # Example variables file
├── .env.example         # Example environment file for renewal script
├── scripts/
│   ├── init.sh          # Droplet initialization script
│   └── renew-certificate.sh  # Certificate renewal script
```

## Key Features

✅ **TLS Termination**: Load balancer handles HTTPS with Let's Encrypt certificates  
✅ **ACME Provider**: Certificates managed via ACME with automatic DNS validation through Cloudflare  
✅ **Auto-renewal**: Certificates automatically renew—just schedule `terraform apply` with cronjob  
✅ **Health Checks**: Load balancer monitors droplet health  
✅ **DNS Management**: Cloudflare DNS records with Terraform  
✅ **Cloudflare Protection**: DNS records proxied through Cloudflare for DDoS protection

## Terraform Outputs

After `terraform apply`, retrieve outputs with:

```bash
terraform output loadbalancer_ip        # Load balancer IP
terraform output droplet_ipv4           # Droplet private IP
terraform output certificate_id         # Certificate ID
terraform output cloudflare_dns_record  # DNS record details
```

## Scaling

To add more droplets to the load balancer:

1. Add more `digitalocean_droplet` resources in `main.tf`
2. Add their IDs to the `droplet_ids` list in the load balancer resource
3. Run `terraform plan` and `terraform apply`

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

## Cost Considerations

**Estimated monthly cost** (nyc3 region):

- Load Balancer: $12/month
- Droplet (s-1vcpu-512mb-10gb): $4/month
- **Total: ~$16/month**

## Troubleshooting

### Certificate Not Issuing

The ACME provider needs to validate DNS records with Cloudflare. This usually takes 1-2 minutes. If it fails:

1. Verify `cloudflare_api_token` has `Zone:DNS:Edit` permissions
2. Verify `cloudflare_zone_id` is correct
3. Check Terraform logs: `terraform apply -var-file="terraform.tfvars"` and look for ACME errors

### Certificate Renewal Not Working

If the cronjob doesn't seem to work:

1. Ensure the script is executable: `chmod +x scripts/renew-certificate.sh`
2. Check the log file: `tail -f terraform-renewal.log`
3. Verify cron is running: `crontab -l`
4. Test manually: `/path/to/scripts/renew-certificate.sh`

### DNS Not Resolving

1. Verify zone ID is correct in Cloudflare
2. Check nameservers are pointing to Cloudflare
3. Allow 24 hours for DNS propagation

### Droplet Not Healthy

Check droplet SSH access:

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
