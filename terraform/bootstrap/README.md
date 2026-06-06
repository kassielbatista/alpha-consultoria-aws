# Terraform State Bootstrap

This directory contains Terraform configuration to create the S3 bucket required for remote state management.

Uses native S3 locking (`use_lockfile = true`) introduced in Terraform 1.10+, which eliminates the need for a DynamoDB table.

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform >= 1.10 installed

## Usage

1. Initialize Terraform:
   ```bash
   cd terraform/bootstrap
   terraform init
   ```

2. Review the plan:
   ```bash
   terraform plan
   ```

3. Apply the configuration:
   ```bash
   terraform apply
   ```

4. After successful creation, return to the main terraform directory and initialize with the S3 backend:
   ```bash
   cd ../
   terraform init
   ```

## Resources Created

- **S3 Bucket**: `alpha-k-tfstate`
  - Versioning enabled
  - Server-side encryption (AES256)
  - Public access blocked

## How Locking Works

Terraform 1.10+ supports native S3 locking via the `use_lockfile` option. When enabled:
- Terraform creates a `.tflock` file in S3 alongside the state file
- This provides the same locking guarantees as DynamoDB but with simpler infrastructure
- No additional AWS resources or costs for DynamoDB

## Important Notes

- The S3 bucket has `prevent_destroy = true` lifecycle rule to prevent accidental deletion
- The bootstrap state is stored locally (in `terraform.tfstate`) - keep this file safe or migrate it
- Do not delete the S3 bucket while the main infrastructure exists
- Requires Terraform 1.10 or later
