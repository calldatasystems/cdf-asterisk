# CDF Asterisk - Dev Environment
# Standalone Asterisk deployment using shared LiteLLM VPC

locals {
  project_name = "cdf"
  environment  = "dev"
  region       = "us-east-2"

  # Instance configuration
  instance_type    = "t3.large"
  root_volume_size = 50

  # Security - restrict to known sources in production
  sip_allowed_cidrs   = ["0.0.0.0/0"] # TODO: Restrict this
  rtp_allowed_cidrs   = ["0.0.0.0/0"] # TODO: Restrict this
  wazo_allowed_cidrs  = ["10.0.0.0/16"] # LiteLLM VPC CIDR

  tags = {
    Project     = "CDF Asterisk"
    Environment = "dev"
    ManagedBy   = "Terraform"
    Repository  = "cdf-asterisk"
  }
}

# Get existing LiteLLM VPC (shared across all dev services)
data "aws_vpc" "litellm" {
  filter {
    name   = "tag:Name"
    values = ["calldata-litellm-dev-vpc"]
  }
}

# Get public subnets from LiteLLM VPC
data "aws_subnets" "litellm_public" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.litellm.id]
  }

  filter {
    name   = "tag:Type"
    values = ["public"]
  }
}

# Deploy standalone Asterisk
module "asterisk" {
  source = "../../modules/asterisk"

  project_name     = local.project_name
  environment      = local.environment
  vpc_id           = data.aws_vpc.litellm.id
  subnet_id        = tolist(data.aws_subnets.litellm_public.ids)[0]
  instance_type    = local.instance_type
  root_volume_size = local.root_volume_size
  allocate_eip     = true

  # Security
  sip_allowed_cidrs  = local.sip_allowed_cidrs
  rtp_allowed_cidrs  = local.rtp_allowed_cidrs
  wazo_allowed_cidrs = local.wazo_allowed_cidrs

  tags = local.tags
}
