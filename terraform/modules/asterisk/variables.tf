# Asterisk Module Variables

variable "project_name" {
  description = "Project name for resource naming"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, stage, prod)"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where Asterisk will be deployed"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID for Asterisk instance"
  type        = string
}

variable "instance_type" {
  description = "EC2 instance type for Asterisk"
  type        = string
  default     = "t3.large"
}

variable "root_volume_size" {
  description = "Size of root EBS volume in GB"
  type        = number
  default     = 50
}

variable "allocate_eip" {
  description = "Whether to allocate an Elastic IP"
  type        = bool
  default     = true
}

variable "sip_allowed_cidrs" {
  description = "CIDR blocks allowed to access SIP ports"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "rtp_allowed_cidrs" {
  description = "CIDR blocks allowed to access RTP ports"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "wazo_allowed_cidrs" {
  description = "CIDR blocks for Wazo platform to access AMI"
  type        = list(string)
}

variable "tags" {
  description = "Additional tags for resources"
  type        = map(string)
  default     = {}
}
