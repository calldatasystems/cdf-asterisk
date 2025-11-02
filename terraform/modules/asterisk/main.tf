# Standalone Asterisk VM Module

locals {
  name_prefix = "${var.project_name}-${var.environment}-asterisk"

  common_tags = merge(
    var.tags,
    {
      Component = "asterisk"
      Service   = "voip"
    }
  )
}

# Security Group for Asterisk
resource "aws_security_group" "asterisk" {
  name_prefix = "${local.name_prefix}-"
  description = "Security group for Asterisk VoIP server"
  vpc_id      = var.vpc_id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-sg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}

# Allow SIP (5060/UDP)
resource "aws_security_group_rule" "sip_udp" {
  type              = "ingress"
  from_port         = 5060
  to_port           = 5060
  protocol          = "udp"
  cidr_blocks       = var.sip_allowed_cidrs
  security_group_id = aws_security_group.asterisk.id
  description       = "SIP signaling (UDP)"
}

# Allow SIP TLS (5061/TCP)
resource "aws_security_group_rule" "sip_tls" {
  type              = "ingress"
  from_port         = 5061
  to_port           = 5061
  protocol          = "tcp"
  cidr_blocks       = var.sip_allowed_cidrs
  security_group_id = aws_security_group.asterisk.id
  description       = "SIP TLS signaling"
}

# Allow RTP media (10000-20000/UDP)
resource "aws_security_group_rule" "rtp" {
  type              = "ingress"
  from_port         = 10000
  to_port           = 20000
  protocol          = "udp"
  cidr_blocks       = var.rtp_allowed_cidrs
  security_group_id = aws_security_group.asterisk.id
  description       = "RTP media streams"
}

# Allow AMI (Asterisk Manager Interface) from Wazo
resource "aws_security_group_rule" "ami" {
  type              = "ingress"
  from_port         = 5038
  to_port           = 5038
  protocol          = "tcp"
  cidr_blocks       = var.wazo_allowed_cidrs
  security_group_id = aws_security_group.asterisk.id
  description       = "Asterisk Manager Interface for Wazo"
}

# Allow all outbound traffic
resource "aws_security_group_rule" "egress" {
  type              = "egress"
  from_port         = 0
  to_port           = 0
  protocol          = "-1"
  cidr_blocks       = ["0.0.0.0/0"]
  security_group_id = aws_security_group.asterisk.id
  description       = "Allow all outbound"
}

# IAM Role for SSM access
resource "aws_iam_role" "asterisk_ssm" {
  name_prefix = "${local.name_prefix}-ssm-"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = local.common_tags
}

# Attach SSM managed policy
resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.asterisk_ssm.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# Instance profile
resource "aws_iam_instance_profile" "asterisk" {
  name_prefix = "${local.name_prefix}-profile-"
  role        = aws_iam_role.asterisk_ssm.name

  tags = local.common_tags
}

# Get latest Debian 12 AMI
data "aws_ami" "debian12" {
  most_recent = true
  owners      = ["136693071363"] # Debian official

  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# User data script for initial setup
data "cloudinit_config" "asterisk" {
  gzip          = true
  base64_encode = true

  part {
    content_type = "text/x-shellscript"
    content      = <<-EOF
      #!/bin/bash
      set -ex

      # Update system
      apt-get update
      DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

      # Install Python for Ansible
      apt-get install -y python3 python3-pip python3-apt

      # Install SSM agent for Debian
      cd /tmp
      wget https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/debian_amd64/amazon-ssm-agent.deb
      dpkg -i amazon-ssm-agent.deb
      systemctl enable amazon-ssm-agent
      systemctl start amazon-ssm-agent

      # Set hostname
      hostnamectl set-hostname ${local.name_prefix}

      echo "Asterisk VM initialization complete"
    EOF
  }
}

# EC2 Instance
resource "aws_instance" "asterisk" {
  ami                    = data.aws_ami.debian12.id
  instance_type          = var.instance_type
  subnet_id              = var.subnet_id
  vpc_security_group_ids = [aws_security_group.asterisk.id]
  iam_instance_profile   = aws_iam_instance_profile.asterisk.name
  user_data_base64       = data.cloudinit_config.asterisk.rendered

  root_block_device {
    volume_type           = "gp3"
    volume_size           = var.root_volume_size
    delete_on_termination = true
    encrypted             = true

    tags = merge(
      local.common_tags,
      {
        Name = "${local.name_prefix}-root"
      }
    )
  }

  tags = merge(
    local.common_tags,
    {
      Name = local.name_prefix
    }
  )

  lifecycle {
    ignore_changes = [
      user_data_base64,
      ami
    ]
  }
}

# Elastic IP (optional)
resource "aws_eip" "asterisk" {
  count    = var.allocate_eip ? 1 : 0
  domain   = "vpc"
  instance = aws_instance.asterisk.id

  tags = merge(
    local.common_tags,
    {
      Name = "${local.name_prefix}-eip"
    }
  )
}
