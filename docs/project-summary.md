# AWS Bastion Host - Security Architecture

> Cloud security patterns for controlled access to private infrastructure

## Overview

**Security problem**: Secure remote access to private cloud resources  
**Solution**: Hardened bastion host with defense-in-depth architecture  
**Tech stack**: AWS VPC, EC2, Security Groups, NACLs, Bash, AWS CLI  
**Threat model**: Internet-based attacks, lateral movement, credential compromise

## Security Concepts Demonstrated

### Network Security
✓ VPC design with public/private isolation  
✓ Security group chaining and reference patterns  
✓ Network ACL configuration (stateless filtering)  
✓ Zero-trust network segmentation

### Access Control
✓ Principle of least privilege  
✓ Defense-in-depth architecture  
✓ Key-based authentication enforcement  
✓ Dynamic IP whitelist management

### Threat Mitigation
✓ Attack surface minimization  
✓ Lateral movement prevention  
✓ Data exfiltration controls (no outbound internet)  
✓ Audit trail via CloudTrail

### AWS Security Features
✓ Security Groups (stateful filtering)  
✓ Network ACLs (stateless packet filtering)  
✓ IAM roles and policies  
✓ VPC network isolation
Value-Driven Technical Decisions

### 1. Design for Operational Efficiency
**Business Challenge**: Infrastructure changes shouldn't require hours of reconfiguration  
**Technical Solution**: Security group references instead of hardcoded IPs  
**Client Impact**: Replace bastion instances in 5 minutes, not 5 hours  
**Cost Savings**: Reduced maintenance overhead = lower long-term costs

### 2. Prevent Common Production Issues
**Business Risk**: SSH access mysteriously breaks, blocking entire team  
## Technical Decisions

### Using Security Group References
**Problem**: Hardcoded IPs break when infrastructure changes  
**Solution**: Reference security group IDs instead  
**Result**: Replace bastion instances without touching private server configs

### Handling Stateless NACLs
**Issue**: SSH connections hang mysteriously  
**Cause**: NACLs need explicit rules for response traffic (ephemeral ports)  
**Fix**: Allow TCP/1024-65535 outbound  
**Lesson**: One of those things you debug once and never forget
```
Public Subnet (DMZ)          Private Subnet (Isolated)
     │                              │
     │ Internet Gateway            │ No Internet Access
     │ Bastion Host                │ App Servers
     │ SSH from admin IP           │ SSH from bastion SG only
     │                              │
     └──────── Controlled Access ──▶
```

## Real-World Applications

This architecture pattern is used by:
- **Enterprises**: Secure access to production databases
- **Compliance**: PCI-DSS, HIPAA require jump host patterns
- **Multi-tenant SaaS**: Customer environment isolation
- **Fintech**: Zero-trust network access

## Skills Demonstrated

**AWS Services**:
- VPC, Subnets, Internet Gateway, Route Tables
- EC2, Security Groups, Network ACLs
- IAM (implicit - CLI permissions)

**Networking Concepts**:
- CIDR notation and IP addressing
- Routing and gateway configuration
- Stateful vs stateless filtering
- TCP port ranges and ephemeral ports

**Scripting & Automation**:
- Bash scripting with error handling
- AWS CLI operations
- Idempotent script design
- Variable substitution and control flow

**Security Best Practices**:
- Defense in depth
- Principle of least privilege
- Network segmentation
- Access control automation

## Potential Interview Questions & Answers

**Q: Why use a bastion host instead of direct SSH?**  
A: Defense in depth - single controlled entry point, easier to audit, can implement additional auth layers (MFA, session recording), reduces attack surface.

**Q: Why security group references vs IP addresses?**  
A: Enables dynamic infrastructure. When bastion IP changes (or you add multiple bastions), no need to update private instance rules. The SG reference remains valid.

**Q: Why do NACLs need ephemeral port rules but security groups don't?**  
A: NACLs are stateless - they evaluate each packet independently. Security groups are stateful - they track connection state and automatically allow response traffic.

**Q: How would you make this production-ready?**  
A: (1) Multi-AZ bastion with Auto Scaling, (2) AWS Systems Manager Session Manager instead of SSH, (3) VPC Flow Logs for monitoring, (4) GuardDuty for threat detection, (5) Separate key pairs per environment, (6) MFA enforcement.

## Files & Documentation

- [README.md](../README.md) - Main project documentation
- [Architecture Diagram](architecture.md) - Visual topology
- [Deployment Guide](deployment.md) - Step-by-step AWS CLI commands
- [VPC Config](../configs/vpc-config.md) - Network details
- [Instance Config](../configs/instance-config.md) - EC2 specs
- [Security Policy](../policies/security-policy.md) - Threat model
- [bastion-ip.sh](../scripts/bastion-ip.sh) - IP update automation

## Portfolio Talking Points

1. **Problem-Solution-Result**: Identified dynamic IP challenge → automated solution → zero manual intervention
2. **Technical Depth**: Explains stateful vs stateless filtering with real examples
3. **Security Focus**: Multi-layer defense, least privilege, zero-trust principles
4. **Automation**: Scripts replace manual console work
5. **Documentation**: Professional README, architecture diagrams, deployment guides

## Next Steps (Enhancements)

- [ ] Multi-AZ deployment for high availability
- [ ] Terraform/CloudFormation for IaC
- [ ] AWS Systems Manager Session Manager
- [ ] VPC Flow Logs + CloudWatch monitoring
- [ ] Bastion Auto Scaling Group
- [ ] AWS Config compliance rules

---

**Author**: Caleb Jonathan  
**GitHub**: [@calebjonathan33](https://github.com/calebjonathan33)  
**Contact**: Available on GitHub profile
