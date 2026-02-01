#!/bin/bash
# Terraform Certificate Renewal Script
# This script runs terraform apply to check for and renew expiring certificates
# Set up a cronjob to run this weekly or daily
# Example cron entry: 0 0 * * 0 /path/to/scripts/renew-certificate.sh

set -e

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

# Change to project directory
cd "$PROJECT_DIR"

# Load environment variables if they exist
if [ -f .env ]; then
  export $(cat .env | grep -v '^#' | xargs)
fi

# Log file
LOG_FILE="$PROJECT_DIR/terraform-renewal.log"

# Function to log messages
log_message() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log_message "Starting Terraform certificate renewal check..."

# Run terraform apply to check and renew certificates
if terraform apply -auto-approve -var-file="terraform.tfvars" -lock=true >> "$LOG_FILE" 2>&1; then
  log_message "Terraform apply completed successfully"
  
  # Get current outputs
  LOADBALANCER_IP=$(terraform output -raw loadbalancer_ip 2>/dev/null || echo "unknown")
  log_message "Current Load Balancer IP: $LOADBALANCER_IP"
else
  log_message "ERROR: Terraform apply failed"
  exit 1
fi

log_message "Certificate renewal check completed"
