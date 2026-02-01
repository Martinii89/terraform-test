terraform workspace select staging
terraform plan -var-file="terraform.staging.tfvars" -out="test.tfplan"