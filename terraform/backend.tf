# Terraform Backend Configuration
# S3 bucket for state management with native S3 locking
#
# IMPORTANT: Before using this backend, you must bootstrap the S3 bucket.
# See terraform/bootstrap/README.md for instructions.

terraform {
  backend "s3" {
    bucket       = "alpha-k-tfstate"
    key          = "prod/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true # Native S3 locking (Terraform 1.10+)
  }
}
