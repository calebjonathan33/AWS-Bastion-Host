# AWS Bastion Host VPC Architecture

Secure bastion host implementation demonstrating AWS networking and security best practices.

## Architecture

Internet → Internet Gateway → Public Subnet (Bastion) → Private Subnet (App Servers)

## Features

- Public/private subnet isolation
- Security group chaining (bastion SG references private SG)
- Dynamic IP whitelist automation
- Network ACLs + Security Groups (defense in depth)

## Technologies

- AWS VPC, EC2, Security Groups, NACLs
- Bash scripting, AWS CLI

## Key Learnings

Security Group References: Private instances allow SSH from bastion's security group (not IP). This enables dynamic scaling without hardcoding IPs.

Stateless vs Stateful: NACLs require explicit inbound + outbound rules. Security groups auto-allow return traffic.

Ephemeral Ports: SSH responses use random client ports (1024-65535). NACLs must explicitly allow these.

## Usage

### Access Bastion

ssh -i ~/.ssh/bastion-key.pem ec2-user@BASTION_PUBLIC_IP

### Access Private Instance via Bastion

Two-step:
ssh -i ~/.ssh/bastion-key.pem ec2-user@BASTION_IP
ssh ec2-user@10.0.2.X

One-command ProxyJump:
ssh -i ~/.ssh/bastion-key.pem -J ec2-user@BASTION_IP ec2-user@10.0.2.X

### Update IP Whitelist

./bastion-ip.sh

## Security Model

Bastion SG: Inbound TCP/22 from admin IP only
Private SG: Inbound TCP/22 from bastion SG
NACL: Inbound TCP/22, Outbound TCP/1024-65535

## Cost

~$0/month (free tier) or ~$17/month for 2x t2.micro instances

## License

MIT
