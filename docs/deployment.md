# Deployment Guide

Step-by-step instructions to recreate this infrastructure from scratch.

## Prerequisites

- AWS account with admin access
- AWS CLI installed and configured (`aws configure`)
- SSH key pair generated locally (`ssh-keygen -t rsa -b 4096`)
- Basic understanding of VPC networking

## Step 1: Create VPC

```bash
# Create VPC
VPC_ID=$(aws ec2 create-vpc \
    --cidr-block 10.0.0.0/16 \
    --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=Bastion-VPC}]' \
    --query 'Vpc.VpcId' \
    --output text)

echo "VPC ID: $VPC_ID"

# Enable DNS hostnames
aws ec2 modify-vpc-attribute \
    --vpc-id $VPC_ID \
    --enable-dns-hostnames
```

## Step 2: Create Internet Gateway

```bash
# Create IGW
IGW_ID=$(aws ec2 create-internet-gateway \
    --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=Bastion-IGW}]' \
    --query 'InternetGateway.InternetGatewayId' \
    --output text)

echo "IGW ID: $IGW_ID"

# Attach to VPC
aws ec2 attach-internet-gateway \
    --vpc-id $VPC_ID \
    --internet-gateway-id $IGW_ID
```

## Step 3: Create Subnets

```bash
# Public subnet
PUB_SUB_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 10.0.1.0/24 \
    --availability-zone us-east-1a \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Public-Subnet}]' \
    --query 'Subnet.SubnetId' \
    --output text)

echo "Public Subnet ID: $PUB_SUB_ID"

# Enable auto-assign public IP
aws ec2 modify-subnet-attribute \
    --subnet-id $PUB_SUB_ID \
    --map-public-ip-on-launch

# Private subnet
PRI_SUB_ID=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 10.0.2.0/24 \
    --availability-zone us-east-1a \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Private-Subnet}]' \
    --query 'Subnet.SubnetId' \
    --output text)

echo "Private Subnet ID: $PRI_SUB_ID"
```

## Step 4: Configure Route Table

```bash
# Get route table ID
RT_ID=$(aws ec2 describe-route-tables \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'RouteTables[0].RouteTableId' \
    --output text)

echo "Route Table ID: $RT_ID"

# Add route to IGW
aws ec2 create-route \
    --route-table-id $RT_ID \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id $IGW_ID

# Associate with public subnet
aws ec2 associate-route-table \
    --route-table-id $RT_ID \
    --subnet-id $PUB_SUB_ID
```

## Step 5: Configure Network ACL

```bash
# Get NACL ID
NACL_ID=$(aws ec2 describe-network-acls \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query 'NetworkAcls[0].NetworkAclId' \
    --output text)

echo "NACL ID: $NACL_ID"

# Allow SSH inbound
aws ec2 create-network-acl-entry \
    --network-acl-id $NACL_ID \
    --rule-number 100 \
    --protocol tcp \
    --port-range From=22,To=22 \
    --cidr-block 0.0.0.0/0 \
    --ingress \
    --rule-action allow

# Allow ephemeral ports outbound
aws ec2 create-network-acl-entry \
    --network-acl-id $NACL_ID \
    --rule-number 110 \
    --protocol tcp \
    --port-range From=1024,To=65535 \
    --cidr-block 0.0.0.0/0 \
    --egress \
    --rule-action allow
```

## Step 6: Create Security Groups

```bash
# Bastion security group
BAS_SG_ID=$(aws ec2 create-security-group \
    --group-name Bastion-SG \
    --description "Security group for bastion host" \
    --vpc-id $VPC_ID \
    --query 'GroupId' \
    --output text)

echo "Bastion SG ID: $BAS_SG_ID"

# Get your public IP
MY_IP=$(curl -s https://checkip.amazonaws.com)/32

# Allow SSH from your IP
aws ec2 authorize-security-group-ingress \
    --group-id $BAS_SG_ID \
    --protocol tcp \
    --port 22 \
    --cidr $MY_IP

# Private security group
PRI_SG_ID=$(aws ec2 create-security-group \
    --group-name Private-SG \
    --description "Security group for private instances" \
    --vpc-id $VPC_ID \
    --query 'GroupId' \
    --output text)

echo "Private SG ID: $PRI_SG_ID"

# Allow SSH from bastion SG (not IP!)
aws ec2 authorize-security-group-ingress \
    --group-id $PRI_SG_ID \
    --protocol tcp \
    --port 22 \
    --source-group $BAS_SG_ID
```

## Step 7: Import SSH Key Pair

```bash
# Import your public key to AWS
aws ec2 import-key-pair \
    --key-name bastion-key \
    --public-key-material fileb://~/.ssh/id_rsa.pub
```

## Step 8: Launch Bastion Instance

```bash
# Get latest Amazon Linux 2023 AMI
AMI_ID=$(aws ec2 describe-images \
    --owners amazon \
    --filters "Name=name,Values=al2023-ami-2023.*-x86_64" \
    --query 'sort_by(Images, &CreationDate)[-1].ImageId' \
    --output text)

echo "AMI ID: $AMI_ID"

# Launch bastion
BAS_INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t2.micro \
    --key-name bastion-key \
    --subnet-id $PUB_SUB_ID \
    --security-group-ids $BAS_SG_ID \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Bastion-Host}]' \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "Bastion Instance ID: $BAS_INSTANCE_ID"

# Wait for instance to be running
aws ec2 wait instance-running --instance-ids $BAS_INSTANCE_ID

# Get public IP
BAS_PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids $BAS_INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PublicIpAddress' \
    --output text)

echo "Bastion Public IP: $BAS_PUBLIC_IP"
```

## Step 9: Launch Private Instance

```bash
# Launch private instance
PRI_INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t2.micro \
    --key-name bastion-key \
    --subnet-id $PRI_SUB_ID \
    --security-group-ids $PRI_SG_ID \
    --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=Private-Instance}]' \
    --query 'Instances[0].InstanceId' \
    --output text)

echo "Private Instance ID: $PRI_INSTANCE_ID"

# Wait for instance to be running
aws ec2 wait instance-running --instance-ids $PRI_INSTANCE_ID

# Get private IP
PRI_PRIVATE_IP=$(aws ec2 describe-instances \
    --instance-ids $PRI_INSTANCE_ID \
    --query 'Reservations[0].Instances[0].PrivateIpAddress' \
    --output text)

echo "Private Instance IP: $PRI_PRIVATE_IP"
```

## Step 10: Save Resource IDs

```bash
# Create logs directory
mkdir -p logs

# Save all IDs
cat > logs/resources-id.txt << EOF
export VPC_ID="$VPC_ID"
export IGW_ID="$IGW_ID"
export PUB_SUB_ID="$PUB_SUB_ID"
export PRI_SUB_ID="$PRI_SUB_ID"
export RT_ID="$RT_ID"
export NACL_ID="$NACL_ID"
export BAS_SG_ID="$BAS_SG_ID"
export PRI_SG_ID="$PRI_SG_ID"
export BAS_INSTANCE_ID="$BAS_INSTANCE_ID"
export PRI_INSTANCE_ID="$PRI_INSTANCE_ID"
export BAS_PUBLIC_IP="$BAS_PUBLIC_IP"
export PRI_PRIVATE_IP="$PRI_PRIVATE_IP"
EOF

echo "✓ Resource IDs saved to logs/resources-id.txt"
```

## Step 11: Test Access

```bash
# Test bastion access
ssh -i ~/.ssh/id_rsa ec2-user@$BAS_PUBLIC_IP

# Copy private key to bastion (for testing)
scp -i ~/.ssh/id_rsa ~/.ssh/id_rsa ec2-user@$BAS_PUBLIC_IP:~/.ssh/

# From bastion, test private instance access
ssh ec2-user@$PRI_PRIVATE_IP
```

## Step 12: Setup IP Update Script

```bash
# Copy script to bastion
scp -i ~/.ssh/id_rsa scripts/bastion-ip.sh ec2-user@$BAS_PUBLIC_IP:~/
scp -i ~/.ssh/id_rsa logs/resources-id.txt ec2-user@$BAS_PUBLIC_IP:~/logs/

# SSH to bastion and test
ssh -i ~/.ssh/id_rsa ec2-user@$BAS_PUBLIC_IP
chmod +x bastion-ip.sh
./bastion-ip.sh
```

## Cleanup (Tear Down)

```bash
# Source the resource IDs
source logs/resources-id.txt

# Terminate instances
aws ec2 terminate-instances --instance-ids $BAS_INSTANCE_ID $PRI_INSTANCE_ID
aws ec2 wait instance-terminated --instance-ids $BAS_INSTANCE_ID $PRI_INSTANCE_ID

# Delete security groups
aws ec2 delete-security-group --group-id $PRI_SG_ID
aws ec2 delete-security-group --group-id $BAS_SG_ID

# Detach and delete IGW
aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID

# Delete subnets
aws ec2 delete-subnet --subnet-id $PUB_SUB_ID
aws ec2 delete-subnet --subnet-id $PRI_SUB_ID

# Delete VPC (this also deletes route table and NACL)
aws ec2 delete-vpc --vpc-id $VPC_ID

# Delete key pair
aws ec2 delete-key-pair --key-name bastion-key

echo "✓ All resources deleted"
```

## Troubleshooting

### Can't SSH to bastion
- Check security group allows your current IP: `curl https://checkip.amazonaws.com`
- Run IP update script: `./bastion-ip.sh`
- Verify instance is running: `aws ec2 describe-instance-status --instance-ids $BAS_INSTANCE_ID`

### Can't SSH to private instance from bastion
- Verify route: `ip route` (should show 10.0.0.0/16)
- Check security group: `aws ec2 describe-security-groups --group-ids $PRI_SG_ID`
- Test connectivity: `ping $PRI_PRIVATE_IP`

### IP update script fails
- Check AWS CLI credentials: `aws sts get-caller-identity`
- Verify IAM permissions: ec2:DescribeSecurityGroups, ec2:AuthorizeSecurityGroupIngress, ec2:RevokeSecurityGroupIngress
- Check resource ID: `echo $BAS_SG_ID`
