# VPC Configuration

> Network security through proper segmentation and access control

## Network Topology

```
VPC: 10.0.0.0/16
├── Public Subnet:  10.0.1.0/24 (AZ: us-east-1a)
│   └── Bastion Host (controlled ingress point)
└── Private Subnet: 10.0.2.0/24 (AZ: us-east-1a)
    └── Application Servers (no direct internet access)
```

**Security principle:** Minimize internet-facing attack surface by isolating workloads in private subnets.

## Routing Tables

### Public Route Table
| Destination | Target |
|------------|--------|
| 10.0.0.0/16 | local |
| 0.0.0.0/0 | Internet Gateway |

### Private Route Table (Implicit)
| Destination | Target |
|------------|--------|
| 10.0.0.0/16 | local |

*Note: Private subnet has no route to Internet Gateway, ensuring isolation*

## Security Groups

### Bastion Security Group
**Inbound Rules:**
- Type: SSH (TCP/22)
- Source: Admin IP/32 (dynamically updated)

**Outbound Rules:**
- All traffic (default)

### Private Instance Security Group
**Inbound Rules:**
- Type: SSH (TCP/22)
- Source: sg-xxxxxxxxx (Bastion SG)
  - *Using SG reference instead of IP enables dynamic scaling*

**Outbound Rules:**
- All traffic (default)

## Network ACLs

### NACL Rules (Stateless - requires explicit bidirectional configuration)

**Inbound:**
- Rule 100: TCP/22 from 0.0.0.0/0 (SSH)

**Outbound:**
- Rule 110: TCP/1024-65535 to 0.0.0.0/0 (Ephemeral ports for SSH responses)

## Security Architecture Decisions

### Security Group References > IP-based Rules
Using security group IDs (`sg-xxxxx`) instead of CIDR blocks for access control.

**Security benefit:** Infrastructure changes don't require security policy updates. Bastion replacement, auto-scaling, or disaster recovery scenarios don't break access control rules. Policy stays coupled to role, not ephemeral infrastructure.

### Layered Filtering (Defense in Depth)
NACLs + Security Groups provide independent security controls at different network layers.

**Security benefit:** Single misconfiguration or vulnerability doesn't bypass all controls. Attack requires compromise of multiple independent security mechanisms.

### Zero Outbound Internet Access (Private Subnet)
Private subnet has no route to Internet Gateway. Workloads cannot initiate outbound connections.

**Security benefit:** Prevents data exfiltration, command-and-control callbacks, and lateral movement to external systems. Reduces blast radius of compromised instances.

### Stateless NACL Configuration
Explicit bidirectional rules required. Inbound SSH (TCP/22) + outbound ephemeral ports (TCP/1024-65535).

**Security consideration:** Stateless evaluation means each packet is independently filtered. Missing ephemeral port rules create functional issues that look like security blocks, causing misdiagnosis and rule weakening.
