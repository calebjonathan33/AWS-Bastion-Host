# Security Architecture & Threat Model

> Security controls and access patterns

## Network Segmentation

### Public Subnet (DMZ)
- **Purpose**: Hardened bastion host - single controlled entry point
- **Exposure**: Internet-facing but restricted to specific IP whitelist
- **Controls**: Security group with /32 CIDR rules, key-based auth only
- **Threat model**: Assumes internet-based attacks, brute force attempts, vulnerability scanning

### Private Subnet (Protected Zone)
- **Purpose**: Production workloads, databases, sensitive systems
- **Exposure**: Zero internet access - reachable only via authenticated bastion
- **Controls**: Security group allows SSH from bastion SG only, no outbound internet routes
- **Threat model**: Assumes lateral movement attempts if perimeter breached

## Access Control Layers

### Layer 1: Network ACLs (Subnet Level)
- Stateless packet filtering
- Rule 100: Allow inbound SSH (TCP/22)
- Rule 110: Allow outbound ephemeral ports (TCP/1024-65535)
- Default deny for all other traffic

### Layer 2: Security Groups (Instance Level)
- Stateful filtering (automatic return traffic)
- Bastion: Allow SSH from admin IP only
- Private: Allow SSH from bastion SG only
- Implicit deny for all other traffic

### Layer 3: Operating System (Instance Level)
- Key-based authentication only (no passwords)
- Regular security updates via `yum update`
- Minimal installed packages (attack surface reduction)

## Automated Access Control

### Challenge
Static IP whitelists break in dynamic environments (DHCP, ISP changes, remote workforce). Manual security group updates create operational friction and security gaps.

### Implementation
Automated script maintains IP whitelist:
1. Queries external service for current public IP
2. Retrieves bastion security group current rules via AWS API
3. Compares current IP against whitelist
4. Updates security group rule if mismatch detected

**Security properties:**
- Idempotent - safe to run repeatedly
- Atomic updates
- Audit trail via CloudTrail API logging
- No credentials stored in script (uses IAM role or AWS CLI config)

```bash
./scripts/bastion-ip.sh

# Automated via cron
*/30 * * * * /path/to/bastion-ip.sh >> /var/log/ip-update.log 2>&1
```

## Security Group Reference Pattern

### Traditional Approach (IP-based)
```
Private SG: Allow SSH from 10.0.1.202/32
Problem: Hardcoded IP breaks when bastion replaced
```

### Modern Approach (SG-based)
```
Private SG: Allow SSH from sg-xxxxxxxxx (Bastion SG)
Benefit: Works regardless of bastion IP changes
```

## Compliance Considerations

### Data Protection
- Private instances isolated from internet
- All access logged via CloudTrail
- Encrypted EBS volumes (not implemented in demo)

### Access Management
- Centralized entry point (bastion)
- Single IP whitelist to maintain
- Easy to revoke access (remove from bastion SG)

### Audit Trail
- VPC Flow Logs (not enabled in demo)
- CloudTrail API logging
- SSH session logging on bastion

## Threat Model

### Protected Against
✓ Direct internet access to private resources
✓ Unauthorized SSH attempts (IP whitelist)
✓ Lateral movement (security groups)
✓ IP spoofing (AWS network controls)

### Not Protected Against
✗ Compromised bastion (need intrusion detection)
✗ Stolen SSH keys (need key rotation policy)
✗ DDoS on bastion (need AWS Shield)
✗ Zero-day exploits (need WAF + patching)

## Recommended Enhancements

1. **Multi-Factor Authentication**: Require MFA for bastion access
2. **Session Manager**: Replace SSH with AWS Systems Manager
3. **Bastion Auto Scaling**: High availability with ASG
4. **VPC Flow Logs**: Network traffic monitoring
5. **GuardDuty**: Threat detection
6. **AWS Config**: Compliance monitoring
