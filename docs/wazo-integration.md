# Integrating Standalone Asterisk with Wazo Platform

This document describes how to configure the Wazo Platform to use the standalone Asterisk server instead of its embedded Asterisk instance.

## Architecture Overview

After this integration:
- **Wazo Platform** - Provides web UI, REST API, and management layer
- **Asterisk Server** - Handles SIP signaling and RTP media (separated)

## Prerequisites

- Standalone Asterisk server deployed and running
- Wazo Platform deployed and accessible
- Network connectivity between Wazo and Asterisk
- Asterisk private IP address

## Integration Steps

### 1. Get Asterisk Connection Details

From the cdf-asterisk deployment:

```bash
cd terraform/environments/dev
terraform output asterisk_private_ip
```

Note the private IP (e.g., `10.0.1.50`)

### 2. Configure Wazo to Use Remote Asterisk

SSH into the Wazo Platform instance:

```bash
aws ssm start-session --target <wazo-instance-id>
```

Edit Wazo configuration to point to remote Asterisk:

```bash
sudo vim /etc/wazo-agid/config.yml
```

Update the Asterisk connection settings:

```yaml
asterisk:
  host: 10.0.1.50  # Asterisk private IP
  port: 5038        # AMI port
  username: wazo
  password: <wazo_ami_secret>
```

### 3. Update Wazo Services

Restart Wazo services to pick up the new configuration:

```bash
sudo systemctl restart wazo-agid
sudo systemctl restart wazo-calld
sudo systemctl restart wazo-confd
```

### 4. Verify Connection

Check that Wazo can connect to the remote Asterisk AMI:

```bash
sudo tail -f /var/log/wazo-agid.log
```

You should see successful AMI connection messages.

### 5. Test SIP Registration

From the Wazo web UI:
1. Navigate to **Services > IPBX > General Settings > SIP Protocol**
2. Verify the SIP server is pointing to the remote Asterisk
3. Create a test SIP endpoint
4. Register a SIP phone and make a test call

### 6. Disable Embedded Asterisk (Optional)

Once the remote Asterisk is working, you can stop the embedded Asterisk on Wazo:

```bash
sudo systemctl stop asterisk
sudo systemctl disable asterisk
```

## Troubleshooting

### AMI Connection Issues

Check AMI connectivity from Wazo to Asterisk:

```bash
telnet 10.0.1.50 5038
```

### SIP Registration Failures

On the Asterisk server, check SIP status:

```bash
aws ssm start-session --target <asterisk-instance-id>
sudo asterisk -r
CLI> sip show peers
CLI> sip show registry
```

### Security Group Issues

Ensure Wazo's security group allows outbound to Asterisk on:
- Port 5038 (AMI)
- Port 5060 (SIP)
- Ports 10000-20000 (RTP)

Ensure Asterisk's security group allows inbound from Wazo VPC CIDR.

## Monitoring

### Check Asterisk Status

```bash
aws ssm start-session --target <asterisk-instance-id>
sudo asterisk -r -x "core show channels"
sudo asterisk -r -x "core show uptime"
```

### View Asterisk Logs

```bash
sudo tail -f /var/log/asterisk/full
```

### CloudWatch Logs

Asterisk logs are automatically shipped to CloudWatch Logs group:
`/aws/ec2/cdf-asterisk-dev`

## Performance Tuning

### Adjust RTP Port Range

If handling high call volumes, increase RTP ports in:
- `terraform/modules/asterisk/main.tf` - Security group rules
- `ansible/roles/asterisk/defaults/main.yml` - Asterisk RTP config

### Scale Asterisk Instance

For production workloads, consider:
- Upgrading to `t3.xlarge` or larger
- Using Auto Scaling with multiple Asterisk servers
- Implementing session border controller (SBC)

## Rollback

To revert to embedded Asterisk:

1. On Wazo, edit `/etc/wazo-agid/config.yml`:
```yaml
asterisk:
  host: localhost
  port: 5038
```

2. Restart Wazo services and re-enable embedded Asterisk:
```bash
sudo systemctl restart wazo-agid wazo-calld wazo-confd
sudo systemctl start asterisk
sudo systemctl enable asterisk
```

## Additional Resources

- [Asterisk Manager Interface (AMI) Documentation](https://docs.asterisk.org/Configuration/Interfaces/Asterisk-Manager-Interface-AMI/)
- [Wazo Platform Architecture](https://wazo-platform.org/documentation)
- [SIP Protocol Configuration](https://docs.asterisk.org/Configuration/Channel-Drivers/SIP/)
