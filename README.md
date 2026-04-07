## AWS Bastion Host Security

Private infrastructure (databases, app servers) stays in **private subnets** with **no internet access**.  
Engineers still need SSH. The safe pattern is a single hardened entry point:

```
Internet → Bastion (public) → Private Servers
```

## Three-Layer Defense

- **NACLs (subnet, stateless):** inbound + outbound rules must both be explicit.
- **Security Groups (instance, stateful):** return traffic is automatically allowed for established connections.
- **System access (SSH keys):** key-based auth only (no passwords).

## Three Friction Points

1) **Ephemeral port gap (NACLs)**  
Allowing inbound `tcp/22` is not enough. For return traffic, allow outbound **`tcp/1024-65535`** or SSH can stall.

2) **Dynamic IP (bastion SG `/32`)**  
If the public IP changes, SSH breaks. Sync the bastion SG rule with the script:
- `scripts/bastion-ip.sh`

3) **SG reference > CIDR (private hosts)**  
Private instances should allow SSH **from the bastion security group** (`sg-...`), not from a bastion IP CIDR. Bastion IPs can change; SG references keep policy stable.

## Network Architecture

```text
┌─────────────────────────────────────┐
│ VPC (10.0.0.0/16)                   │
│                                     │
│  ┌──────────────┐  ┌─────────────┐  │
│  │ Public       │  │ Private     │  │
│  │ 10.0.1.0/24  │  │ 10.0.2.0/24 │  │
│  │              │  │             │  │
│  │ Bastion ─────────→ App/DB     │  │
│  │              │  │             │  │
│  └──────┬───────┘  └─────────────┘  │
│         │                            │
└─────────┼────────────────────────────┘
          │
    Internet Gateway
```
