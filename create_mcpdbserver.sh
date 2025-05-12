#!/bin/bash

# Script to create RDS MySQL 8.0.41 instance
# Configuration:
# - Single-AZ
# - DB cluster identifier: mcpdbserver
# - Master username: admin
# - Instance class: db.t3.medium
# - Storage: gp3, 50GB
# - No public access

echo "Creating RDS MySQL instance..."

# Get default VPC ID
DEFAULT_VPC_ID=$(aws ec2 describe-vpcs --filters "Name=isDefault,Values=true" --query "Vpcs[0].VpcId" --output text)
echo "Using default VPC: $DEFAULT_VPC_ID"

# Get subnet IDs from default VPC - fixed format
SUBNET_IDS=$(aws ec2 describe-subnets --filters "Name=vpc-id,Values=$DEFAULT_VPC_ID" --query "Subnets[*].SubnetId" --output text)
echo "Available subnets: $SUBNET_IDS"

# Create DB subnet group with properly formatted subnet IDs
echo "Creating DB subnet group..."
aws rds create-db-subnet-group \
    --db-subnet-group-name mcpdbserver-subnet-group \
    --db-subnet-group-description "Subnet group for mcpdbserver" \
    --subnet-ids $(echo $SUBNET_IDS)

# Check if security group exists or create new one
echo "Checking for existing security group..."
SG_NAME="rds-mysql-sg"
SG_ID=$(aws ec2 describe-security-groups --filters "Name=group-name,Values=$SG_NAME" --query "SecurityGroups[0].GroupId" --output text)

if [ "$SG_ID" == "None" ] || [ -z "$SG_ID" ]; then
    echo "Creating new security group for MySQL..."
    SG_ID=$(aws ec2 create-security-group \
        --group-name $SG_NAME \
        --description "Security group for MySQL RDS" \
        --vpc-id $DEFAULT_VPC_ID \
        --output text --query 'GroupId')

    # Add rule to allow MySQL traffic (port 3306)
    aws ec2 authorize-security-group-ingress \
        --group-id $SG_ID \
        --protocol tcp \
        --port 3306 \
        --cidr 0.0.0.0/0

    echo "Created security group: $SG_ID"
else
    echo "Using existing security group: $SG_ID"
fi

# Prompt for password (more secure than hardcoding)
echo "Please enter the master password for the RDS instance:"
read -s MASTER_PASSWORD

# Create the RDS instance
echo "Creating RDS MySQL instance 'mcpdbserver'..."
aws rds create-db-instance \
    --db-instance-identifier mcpdbserver \
    --db-instance-class db.t3.medium \
    --engine mysql \
    --engine-version 8.0.41 \
    --master-username admin \
    --master-user-password "$MASTER_PASSWORD" \
    --allocated-storage 50 \
    --storage-type gp3 \
    --vpc-security-group-ids $SG_ID \
    --db-subnet-group-name mcpdbserver-subnet-group \
    --no-publicly-accessible \
    --no-multi-az

echo "RDS MySQL instance creation initiated. It may take several minutes to complete."
echo "You can check the status with: aws rds describe-db-instances --db-instance-identifier mcpdbserver --query 'DBInstances[0].DBInstanceStatus'"
