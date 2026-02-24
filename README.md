# AWS Bastion Host

> Secure access pattern for private infrastructure using defense-in-depth

A bastion host implementation demonstrating AWS network security fundamentals: subnet isolation, layered access control, and automated security rule management.

## The Security Challenge

Production workloads (databases, app servers) shouldn't be directly exposed to the internet. But engineers still need SSH access for troubleshooting and maintenance.

**Common approaches:**
- **Direct public access**: Every instance exposed = massive attack surface
- **VPN**: Adds complexity, single point of failure, additional service to secure
- **Manual bastion + IP whitelisting**: Works until IPs change, manual security group updates

**This approach:** Hardened jump server with automated access control and layered security.

**The Setup:**
```
Internet → Public Bastion → Private Servers
```

## Security Architecture

- **Network segmentation** - Public/private subnet isolation via VPC design
- **Controlled entry point** - Single bastion host vs multiple exposed instances
- **Security group chaining** - Private resources trust bastion's SG, not ephemeral IPs
- **Stateless + stateful filtering** - NACLs and Security Groups for defense-in-depth
- **Automated access control** - Dynamic IP whitelisting without manual intervention
- **Key-based authentication** - No password authentication anywhere

Attack surface: 1 hardened SSH endpoint instead of N exposed servers.

## Quick Start

```bash
# SSH to bastion
ssh -i ~/.ssh/bastion-key.pem ec2-user@BASTION_IP

# SSH to private instance (through bastion)
ssh -i ~/.ssh/bastion-key.pem -J ec2-user@BASTION_IP ec2-user@10.0.2.X

# Update your IP whitelist
```bash
./scripts/bastion-ip.sh
```

## Architecture Notes

Your home/office IP changes (thanks, ISP). Suddenly you can't SSH. You have to log into AWS console, find the security group, update the rule. Gets old fast.

**[The solution](scripts/bastion-ip.sh)** - 8 lines of bash that:
- Checks your current public IP
- Compares it to the bastion security group
- Updates the rule if it changed
- Takes 2 seconds to run

Run it manually or throw it in a cron job. Problem solved.

## Architecture Notes
Layer 1 (Network): Packet filtering at subnet level
Layer 2 (Instance): Connection-level security groups
Layer 3 (System): Key-based authentication only
```

One layer compromised? The others hold. That's how you design for real-world threats.

### The Technical Gotcha That Costs Hours
### The Stateful vs Stateless Thing
- **Security Groups**: Stateful - return traffic is automatic
- **NACLs**: Stateless - you must explicitly allow responses

This catches people: SSH requests work but hang because NACLs block the return traffic. Fix: Allow ephemeral ports (1024-65535) outbound in your NACL.

### Defense in Depth
```
Network Layer: NACL filtering at subnet level
Instance Layer: Security Groups at instance level  
System Layer: Key-based auth only (no passwords)
```

One layer fails? The others catch it.

## Automated Access Control

Dynamic IP environments require automated whitelist management. When client IPs change (DHCP, ISP reassignment), static rules break access.

**[The automation](scripts/bastion-ip.sh):**
- Detects current public IP via external service
- Queries bastion security group for current whitelist
- Compares and updates rules if needed
- Idempotent operation - safe to run repeatedly

```bash
./scripts/bastion-ip.sh
```

Can be scheduled via cron for automatic updates.

## Security Design Patterns

### Defense in Depth
```
Layer 1 (Network): NACL packet filtering at subnet boundary
Layer 2 (Instance): Security Groups stateful filtering
Layer 3 (System): Key-based SSH authentication
```

Multiple independent security controls. Compromise of one layer doesn't expose the system.

### Stateful vs Stateless Filtering
- **Security Groups**: Stateful - automatically allow return traffic
- **NACLs**: Stateless - require explicit bidirectional rules

**Common issue:** NACL allows inbound TCP/22 but blocks outbound ephemeral ports (1024-65535). Result: SSH handshake succeeds, connection hangs. NACLs must explicitly permit response traffic.

### Security Group References
Private instances allow SSH from `sg-bastion-xxxxx` instead of hardcoded CIDR blocks.

**Benefit:** Bastion IP can change (instance replacement, auto-scaling, disaster recovery) without requiring updates to downstream security group rules. Security policy remains stable through infrastructure changes.

## Network Architecture

```
┌─────────────────────────────────────┐
│  VPC (10.0.0.0/16)                 │
│                                     │
│  ┌──────────────┐  ┌─────────────┐ │
│  │ Public       │  │ Private     │ │
│  │ 10.0.1.0/24 │  │ 10.0.2.0/24 │ │
│  │             │  │             │ │
│  │  Bastion ────────→ App       │ │
│  │  (hardened)  │  │ (isolated) │ │
│  └──────┬───────┘  └─────────────┘ │
│         │                           │
└─────────┼───────────────────────────┘
          │
    Internet Gateway
```

**Security boundaries:**
- Internet → Public subnet: Filtered by bastion SG (single IP/32 whitelist)
- Public → Private subnet: Filtered by private SG (bastion SG reference only)
- Private subnet → Internet: No route exists (zero outbound internet access)

## Usage

```bash
# SSH to bastion
ssh -i ~/.ssh/bastion-key.pem ec2-user@BASTION_IP

# SSH to private instance (through bastion)
ssh -i ~/.ssh/bastion-key.pem -J ec2-user@BASTION_IP ec2-user@10.0.2.X

# Update IP whitelist
./scripts/bastion-ip.sh
```

## Project Structure

```
.
├── scripts/
│   └── bastion-ip.sh          # Automated IP whitelist management
├── configs/
│   ├── vpc-config.md          # Network topology details
│   └── instance-config.md     # SSH access patterns
├── docs/
│   ├── architecture.md        # Detailed diagrams
│   └── deployment.md          # AWS CLI deployment steps
└── policies/
    └── security-policy.md     # Threat model and controls
```

## Implementation Details

**Tech:** AWS VPC, EC2, Security Groups, NACLs | Bash, AWS CLI  
**Cost:** ~$17/month (2x t2.micro) or free tier eligible  
**Deployment:** [Full guide](docs/deployment.md)

## Production Enhancements

Additional security controls for production deployments:

- **High availability**: Multi-AZ bastion with auto-scaling
- **Session logging**: AWS Systems Manager Session Manager for audit trails
- **Network monitoring**: VPC Flow Logs for traffic analysis
- **Threat detection**: GuardDuty integration for anomaly detection
- **Intrusion detection**: Host-based IDS on bastion instance

## License

MIT

---

**Caleb Jonathan** | [GitHub](https://github.com/calebjonathan33)

Cloud security infrastructure.

---

Made by [Caleb Jonathan](https://github.com/calebjonathan33)
