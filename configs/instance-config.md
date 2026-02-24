# EC2 Instance Configuration

> Practical specs that balance cost and functionality

## Instance Specifications

### Bastion Host
- **Instance Type**: t2.micro (free tier eligible)
- **AMI**: Amazon Linux 2023
- **Network**: Public Subnet (10.0.1.0/24)
- **Public IP**: Auto-assigned
- **Key Pair**: bastion-key
- **Security Group**: Bastion-SG
- **Monthly Cost**: ~$8.50 or $0 (free tier)
- **Purpose**: Secure entry point - think of it as your infrastructure's front door

### Private Instance
- **Instance Type**: t2.micro (free tier eligible)
- **AMI**: Amazon Linux 2023
- **Network**: Private Subnet (10.0.2.0/24)
- **Public IP**: None (by design)
- **Key Pair**: bastion-key
- **Security Group**: Private-SG
- **Monthly Cost**: ~$8.50 or $0 (free tier)
- **Purpose**: Represents production workloads - databases, app servers, etc.

## SSH Access Patterns

### Direct Bastion Access
```bash
ssh -i ~/.ssh/bastion-key.pem ec2-user@<BASTION_PUBLIC_IP>
```

### Two-Step Private Access
```bash
# Step 1: Connect to bastion
ssh -i ~/.ssh/bastion-key.pem ec2-user@<BASTION_PUBLIC_IP>

# Step 2: From bastion, connect to private instance
ssh ec2-user@10.0.2.X
```

### ProxyJump (Single Command)
```bash
ssh -i ~/.ssh/bastion-key.pem \
    -J ec2-user@<BASTION_PUBLIC_IP> \
    ec2-user@10.0.2.X
```

### ProxyCommand (Alternative)
```bash
ssh -i ~/.ssh/bastion-key.pem \
    -o ProxyCommand="ssh -W %h:%p -i ~/.ssh/bastion-key.pem ec2-user@<BASTION_PUBLIC_IP>" \
    ec2-user@10.0.2.X
```

## Key Management

**Production Best Practice**: Use separate key pairs for bastion and private instances

**Demo Configuration**: Same key for simplicity (bastion-key)

**Key Transfer**: Private key stored on bastion for demo purposes:
```bash
scp -i ~/.ssh/bastion-key.pem ~/.ssh/bastion-key.pem ec2-user@<BASTION_IP>:~/.ssh/
```

## Security Considerations

1. **Principle of Least Privilege**: Private instances only accessible through bastion
2. **Key Rotation**: Regularly rotate SSH keys (not implemented in demo)
3. **Session Logging**: Consider AWS Systems Manager Session Manager for audit trails
4. **Multi-Factor Authentication**: Consider requiring MFA for bastion access (not implemented)
