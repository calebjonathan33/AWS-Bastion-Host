# Architecture Diagram

## Network Topology

```
┌─────────────────────────────────────────────────────────────────┐
│                          AWS Cloud                               │
│  ┌───────────────────────────────────────────────────────────┐  │
│  │                   VPC (10.0.0.0/16)                       │  │
│  │                                                            │  │
│  │  ┌────────────────────────┐  ┌─────────────────────────┐ │  │
│  │  │  Public Subnet         │  │  Private Subnet         │ │  │
│  │  │  10.0.1.0/24          │  │  10.0.2.0/24           │ │  │
│  │  │                        │  │                         │ │  │
│  │  │  ┌──────────────────┐ │  │  ┌──────────────────┐  │ │  │
│  │  │  │  Bastion Host    │ │  │  │ Private Instance │  │ │  │
│  │  │  │  10.0.1.202     │─────┼──▶│  10.0.2.78      │  │ │  │
│  │  │  │                  │ │  │  │                  │  │ │  │
│  │  │  │  Bastion-SG      │ │  │  │  Private-SG      │  │ │  │
│  │  │  │  SSH from admin  │ │  │  │  SSH from BAS-SG │  │ │  │
│  │  │  └─────────┬────────┘ │  │  └──────────────────┘  │ │  │
│  │  │            │           │  │                         │ │  │
│  │  └────────────┼───────────┘  └─────────────────────────┘ │  │
│  │               │                                           │  │
│  │               │                                           │  │
│  │  ┌────────────▼───────────┐                              │  │
│  │  │   Internet Gateway     │                              │  │
│  │  │   igw-xxxxxxxxxx       │                              │  │
│  │  └────────────┬───────────┘                              │  │
│  │               │                                           │  │
│  └───────────────┼───────────────────────────────────────────┘  │
│                  │                                               │
└──────────────────┼───────────────────────────────────────────────┘
                   │
         ┌─────────▼──────────┐
         │     Internet       │
         │                    │
         │  ┌──────────────┐  │
         │  │ Admin Client │  │
         │  │ Dynamic IP   │  │
         │  └──────────────┘  │
         └────────────────────┘
```

## Traffic Flow

### SSH to Bastion (Direct Access)
```
Admin Workstation (dynamic IP)
    │
    │ [1] SSH (TCP/22)
    │
    ▼
Internet Gateway
    │
    │ [2] Route: 0.0.0.0/0 → IGW
    │
    ▼
Network ACL (Subnet Level)
    │ [3] Rule 100: Allow TCP/22 inbound
    ▼
Security Group (Instance Level)
    │ [4] Bastion-SG: Allow TCP/22 from admin IP/32
    ▼
Bastion Host (10.0.1.202)
```

### SSH to Private Instance (via Bastion)
```
Bastion Host (10.0.1.202)
    │
    │ [1] SSH (TCP/22) to 10.0.2.78
    │
    ▼
VPC Routing
    │ [2] Local route: 10.0.0.0/16 → local
    ▼
Network ACL (Subnet Level)
    │ [3] Rule 100: Allow TCP/22 inbound
    ▼
Security Group (Instance Level)
    │ [4] Private-SG: Allow TCP/22 from sg-xxxxxxxxx (Bastion-SG)
    ▼
Private Instance (10.0.2.78)
```

### Return Traffic (Stateless NACL)
```
Private Instance (10.0.2.78)
    │
    │ [1] SSH Response (TCP/random port 1024-65535)
    │
    ▼
Security Group (Stateful)
    │ [2] Automatically allows return traffic
    ▼
Network ACL (Stateless)
    │ [3] Rule 110: Allow TCP/1024-65535 outbound
    │     ↑ CRITICAL: Without this, SSH hangs!
    ▼
Bastion Host (10.0.1.202)
```

## Security Layers

```
┌────────────────────────────────────────────────┐
│            Defense in Depth Model              │
├────────────────────────────────────────────────┤
│                                                │
│  Layer 1: Network ACL (Subnet-wide)           │
│  ├─ Stateless filtering                       │
│  ├─ Allow TCP/22 inbound                      │
│  └─ Allow TCP/1024-65535 outbound             │
│                                                │
│  Layer 2: Security Group (Instance-specific)  │
│  ├─ Stateful filtering                        │
│  ├─ Bastion: SSH from admin IP only           │
│  └─ Private: SSH from Bastion SG only         │
│                                                │
│  Layer 3: Operating System                    │
│  ├─ Key-based authentication                  │
│  ├─ No password login                         │
│  └─ Minimal installed packages                │
│                                                │
└────────────────────────────────────────────────┘
```

## Auto-Update Flow

```
┌──────────────────────────────────────────────────────┐
│         Dynamic IP Update Process                    │
└──────────────────────────────────────────────────────┘

Cron Job / Manual Execution
         │
         ▼
┌────────────────────────┐
│  bastion-ip.sh script  │
└────────┬───────────────┘
         │
         ├─[1]─▶ curl checkip.amazonaws.com
         │       (Get current public IP)
         │
         ├─[2]─▶ aws ec2 describe-security-groups
         │       (Get current whitelisted IP)
         │
         ├─[3]─▶ Compare IPs
         │       Same? → Exit (no change needed)
         │       Different? → Continue
         │
         ├─[4]─▶ aws ec2 revoke-security-group-ingress
         │       (Remove old IP rule)
         │
         └─[5]─▶ aws ec2 authorize-security-group-ingress
                 (Add new IP rule)
```

## Component Relationships

```
┌─────────────────────────────────────────────────┐
│              Resource Dependencies              │
└─────────────────────────────────────────────────┘

VPC
 ├── Internet Gateway (attached)
 ├── Subnets
 │   ├── Public Subnet
 │   │   ├── Route Table → IGW
 │   │   ├── Network ACL
 │   │   └── Bastion Instance
 │   │       └── Security Group → Bastion-SG
 │   │
 │   └── Private Subnet
 │       ├── Route Table (local only)
 │       ├── Network ACL (same as public)
 │       └── Private Instance
 │           └── Security Group → Private-SG
 │                   └── References Bastion-SG
 │
 └── Security Groups
     ├── Bastion-SG (SSH from admin IP)
     └── Private-SG (SSH from Bastion-SG) ◀───┐
                                               │
                     SG Reference (not IP) ────┘
```
