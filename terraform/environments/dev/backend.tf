# Terraform Backend Configuration
# S3 backend for remote state storage with DynamoDB locking

terraform {
  backend "s3" {
    bucket         = "cdf-asterisk-terraform-state"
    key            = "dev/terraform.tfstate"
    region         = "us-east-2"
    encrypt        = true
    dynamodb_table = "cdf-asterisk-terraform-locks"
  }
}
