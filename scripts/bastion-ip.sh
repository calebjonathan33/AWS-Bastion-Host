#!/bin/bash
# Automatically updates bastion security group with current public IP
# Prevents manual AWS console updates when IP changes

source ../logs/resources-id.txt

CURRENT_IP=$(curl -s https://checkip.amazonaws.com)/32
OLD_IP=$(aws ec2 describe-security-groups --group-ids $BAS_SG_ID --query 'SecurityGroups[0].IpPermissions[?FromPort==`22`].IpRanges[0].CidrIp' --output text)

[ "$OLD_IP" == "$CURRENT_IP" ] && echo "✓ IP already whitelisted: $CURRENT_IP" && exit 0
[ -n "$OLD_IP" ] && aws ec2 revoke-security-group-ingress --group-id $BAS_SG_ID --protocol tcp --port 22 --cidr $OLD_IP 2>/dev/null
aws ec2 authorize-security-group-ingress --group-id $BAS_SG_ID --protocol tcp --port 22 --cidr $CURRENT_IP > /dev/null 2>&1
echo "✓ Updated bastion SG from $OLD_IP → $CURRENT_IP"
