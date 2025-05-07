#!/bin/bash

KEY_NAME="aws"
TAG_NAME="admin-station"
# REGION="us-east-1"
AMI_ID="ami-084568db4383264d4"
INSTANCE_TYPE="t2.large"



# Create key pair
rm -f "${KEY_NAME}.pem"
aws ec2 create-key-pair \
  --region $REGION \
  --key-name $KEY_NAME \
  --query 'KeyMaterial' \
  --output text > "${KEY_NAME}.pem"
chmod 400 "${KEY_NAME}.pem"

# Create Security Group
SG_ID=$(aws ec2 create-security-group \
  --region $REGION \
  --group-name "$TAG_NAME-sg" \
  --description "Security group for $TAG_NAME" \
  --query 'GroupId' \
  --output text)

# Allow SSH access to the security group (port 22)
aws ec2 authorize-security-group-ingress \
  --region $REGION \
  --group-id $SG_ID \
  --protocol tcp \
  --port 22 \
  --cidr 0.0.0.0/0

# Optionally, allow HTTP access (port 80)
aws ec2 authorize-security-group-ingress \
  --region $REGION \
  --group-id $SG_ID \
  --protocol tcp \
  --port 80 \
  --cidr 0.0.0.0/0

# Launch EC2 instance with Security Group
INSTANCE_ID=$(aws ec2 run-instances \
  --region $REGION \
  --image-id $AMI_ID \
  --count 1 \
  --instance-type $INSTANCE_TYPE \
  --key-name $KEY_NAME \
  --security-group-ids $SG_ID \
  --tag-specifications "ResourceType=instance,Tags=[{Key=Name,Value=$TAG_NAME}]" \
  --block-device-mappings "[{\"DeviceName\":\"/dev/sda1\",\"Ebs\":{\"VolumeSize\":80,\"DeleteOnTermination\":true}}]" \
  --query 'Instances[0].InstanceId' \
  --output text)

echo "Waiting for instance $INSTANCE_ID to be running..."
aws ec2 wait instance-running --region $REGION --instance-ids $INSTANCE_ID

# Allocate Elastic IP
ALLOC_ID=$(aws ec2 allocate-address --region $REGION --query 'AllocationId' --output text)

# Associate EIP with instance
ASSOC_ID=$(aws ec2 associate-address \
  --region $REGION \
  --instance-id $INSTANCE_ID \
  --allocation-id $ALLOC_ID \
  --query 'AssociationId' \
  --output text)

# Tag Elastic IP allocation
aws ec2 create-tags \
  --region $REGION \
  --resources $ALLOC_ID \
  --tags Key=Name,Value=$TAG_NAME

echo "Instance $INSTANCE_ID launched with Security Group $SG_ID and tagged as '$TAG_NAME'"
