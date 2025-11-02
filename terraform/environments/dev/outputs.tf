# Dev Environment Outputs

output "asterisk_instance_id" {
  description = "Asterisk EC2 instance ID"
  value       = module.asterisk.instance_id
}

output "asterisk_private_ip" {
  description = "Asterisk private IP address"
  value       = module.asterisk.private_ip
}

output "asterisk_public_ip" {
  description = "Asterisk public IP address"
  value       = module.asterisk.public_ip
}

output "asterisk_elastic_ip" {
  description = "Asterisk Elastic IP address"
  value       = module.asterisk.elastic_ip
}

output "ssm_connect_command" {
  description = "AWS SSM command to connect to Asterisk instance"
  value       = module.asterisk.ssm_command
}

output "asterisk_cli_command" {
  description = "Command to access Asterisk CLI"
  value       = module.asterisk.asterisk_cli_command
}

output "vpc_id" {
  description = "Shared VPC ID"
  value       = data.aws_vpc.litellm.id
}

output "integration_notes" {
  description = "Notes for integrating with Wazo Platform"
  value       = <<-EOT
    Asterisk Deployment Complete!

    Private IP: ${module.asterisk.private_ip}
    Public IP: ${module.asterisk.public_ip}

    Next Steps:
    1. Run Ansible playbook to install and configure Asterisk
    2. Configure Wazo Platform to use this Asterisk server:
       - Set AMI connection to ${module.asterisk.private_ip}:5038
       - Update SIP trunk configuration
    3. Test SIP registration and call routing

    See docs/wazo-integration.md for detailed instructions.
  EOT
}
