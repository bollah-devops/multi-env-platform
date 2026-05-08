#!/bin/bash

echo "=== Environment Update Script ==="
echo ""

# Get current personal IP
MY_IP=$(curl -s -4 ifconfig.me)
echo "Your current IP: $MY_IP"

# Get server IPs from AWS
STAGING_IP=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=staging-app-server" \
            "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].PublicIpAddress' \
  --output text)

PRODUCTION_IP=$(aws ec2 describe-instances \
  --filters "Name=tag:Name,Values=production-app-server" \
            "Name=instance-state-name,Values=running" \
  --query 'Reservations[*].Instances[*].PublicIpAddress' \
  --output text)

echo "Staging IP:    $STAGING_IP"
echo "Production IP: $PRODUCTION_IP"
echo ""

# Get security group IDs
STAGING_SG=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=staging-app-sg" \
  --query 'SecurityGroups[*].GroupId' \
  --output text)

PRODUCTION_SG=$(aws ec2 describe-security-groups \
  --filters "Name=group-name,Values=production-app-sg" \
  --query 'SecurityGroups[*].GroupId' \
  --output text)

# Update security groups — revoke all existing SSH rules first
echo "Updating security groups..."

# Remove all existing SSH ingress rules from staging
aws ec2 describe-security-groups \
  --group-ids $STAGING_SG \
  --query 'SecurityGroups[*].IpPermissions[?FromPort==`22`].IpRanges[*].CidrIp' \
  --output text | tr '\t' '\n' | while read cidr; do
    if [ ! -z "$cidr" ]; then
      aws ec2 revoke-security-group-ingress \
        --group-id $STAGING_SG \
        --protocol tcp --port 22 --cidr $cidr 2>/dev/null
    fi
done

# Remove all existing SSH ingress rules from production
aws ec2 describe-security-groups \
  --group-ids $PRODUCTION_SG \
  --query 'SecurityGroups[*].IpPermissions[?FromPort==`22`].IpRanges[*].CidrIp' \
  --output text | tr '\t' '\n' | while read cidr; do
    if [ ! -z "$cidr" ]; then
      aws ec2 revoke-security-group-ingress \
        --group-id $PRODUCTION_SG \
        --protocol tcp --port 22 --cidr $cidr 2>/dev/null
    fi
done

# Add new SSH rule with current IP
aws ec2 authorize-security-group-ingress \
  --group-id $STAGING_SG \
  --protocol tcp --port 22 --cidr $MY_IP/32

aws ec2 authorize-security-group-ingress \
  --group-id $PRODUCTION_SG \
  --protocol tcp --port 22 --cidr $MY_IP/32

echo "Security groups updated with $MY_IP/32"
echo ""

# Update Ansible inventory files
cat > ~/Documents/multi-env-platform/ansible/inventory-staging.ini << INVENTORY
[staging]
staging-server ansible_host=$STAGING_IP ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/devops-key.pem
INVENTORY

cat > ~/Documents/multi-env-platform/ansible/inventory-production.ini << INVENTORY
[production]
prod-server ansible_host=$PRODUCTION_IP ansible_user=ubuntu ansible_ssh_private_key_file=~/.ssh/devops-key.pem
INVENTORY

echo "Inventory files updated"
echo ""

# Update terraform.tfvars for both environments
cat > ~/Documents/multi-env-platform/terraform/environments/staging/terraform.tfvars << TFVARS
key_name = "devops-key"
your_ip  = "$MY_IP/32"
TFVARS

cat > ~/Documents/multi-env-platform/terraform/environments/production/terraform.tfvars << TFVARS
key_name = "devops-key"
your_ip  = "$MY_IP/32"
TFVARS

echo "Terraform tfvars updated"
echo ""

# Clear old SSH known hosts entries and accept new ones
echo "Updating SSH known hosts..."
ssh-keygen -R $STAGING_IP 2>/dev/null
ssh-keygen -R $PRODUCTION_IP 2>/dev/null
ssh-keyscan -H $STAGING_IP >> ~/.ssh/known_hosts 2>/dev/null
ssh-keyscan -H $PRODUCTION_IP >> ~/.ssh/known_hosts 2>/dev/null

echo "SSH known hosts updated"
echo ""

# Test connections
echo "Testing connections..."
ansible staging -i ~/Documents/multi-env-platform/ansible/inventory-staging.ini -m ping
ansible production -i ~/Documents/multi-env-platform/ansible/inventory-production.ini -m ping

echo ""
echo "=== Done ==="
echo "Staging:    http://$STAGING_IP"
echo "Production: http://$PRODUCTION_IP"
