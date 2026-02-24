#!/bin/bash

cd /home/ca-eb/aws-bastion-project

# Reset to first real commit, keeping all changes staged
git reset --soft 66f78e7

# Create single clean commit
git commit -m "feat: AWS Bastion Host - secure access to private infrastructure

Complete implementation of hardened bastion host architecture for secure SSH access.

Network Architecture:
- VPC with public/private subnet isolation (10.0.0.0/16)
- Bastion host in DMZ (public subnet) for controlled entry point
- Private instances completely isolated from internet
- Security group reference pattern enables dynamic infrastructure changes

Security Implementation:
- Defense-in-depth: Network ACLs + Security Groups + SSH key authentication
- Automated IP whitelist management script (bastion-ip.sh)
- Key-based authentication enforced system-wide
- Zero outbound internet access from private subnet

Documentation:
- Complete AWS CLI deployment guide with step-by-step instructions
- Network topology diagrams and traffic flow visualizations
- Security threat model and control analysis
- Configuration examples for VPC, subnets, security groups, NACLs

Automation:
- bastion-ip.sh: Dynamic IP whitelist updates
- Idempotent operations safe for repeated execution
- CloudTrail audit logging integration

Tech Stack: AWS VPC, EC2, Security Groups, Network ACLs, Bash, AWS CLI
Cost: ~\$17/month (2x t2.micro instances, free tier eligible)
Deployment Time: ~30 minutes with provided scripts"

# Force push to replace history
git push -f origin main

echo "Git history cleaned successfully!"
