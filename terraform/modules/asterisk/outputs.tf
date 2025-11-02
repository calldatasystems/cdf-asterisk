# Asterisk Module Outputs

output "instance_id" {
  description = "EC2 instance ID"
  value       = aws_instance.asterisk.id
}

output "private_ip" {
  description = "Private IP address"
  value       = aws_instance.asterisk.private_ip
}

output "public_ip" {
  description = "Public IP address (if EIP allocated)"
  value       = var.allocate_eip ? aws_eip.asterisk[0].public_ip : aws_instance.asterisk.public_ip
}

output "elastic_ip" {
  description = "Elastic IP address (if allocated)"
  value       = var.allocate_eip ? aws_eip.asterisk[0].public_ip : null
}

output "security_group_id" {
  description = "Security group ID"
  value       = aws_security_group.asterisk.id
}

output "ssm_command" {
  description = "Command to connect via AWS Systems Manager"
  value       = "aws ssm start-session --target ${aws_instance.asterisk.id}"
}

output "asterisk_cli_command" {
  description = "Command to access Asterisk CLI via SSM"
  value       = "aws ssm start-session --target ${aws_instance.asterisk.id} --document-name AWS-StartInteractiveCommand --parameters command='sudo asterisk -r'"
}
