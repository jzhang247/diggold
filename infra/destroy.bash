#!/bin/bash

KEY_NAME="aws"
TAG_NAME="admin-station"
REGION="us-east-1"


# Find and terminate instance(s)
INSTANCE_IDS=$(aws ec2 describe-instances \
  --region $REGION \
  --filters "Name=tag:Name,Values=$TAG_NAME" "Name=instance-state-name,Values=running,stopped,pending" \
  --query "Reservations[*].Instances[*].InstanceId" \
  --output text)

if [ -n "$INSTANCE_IDS" ]; then
  echo "Terminating instance(s): $INSTANCE_IDS"
  aws ec2 terminate-instances --region $REGION --instance-ids $INSTANCE_IDS
  aws ec2 wait instance-terminated --region $REGION --instance-ids $INSTANCE_IDS
fi

# Disassociate and release Elastic IPs
ALLOC_IDS=$(aws ec2 describe-addresses \
  --region $REGION \
  --filters "Name=tag:Name,Values=$TAG_NAME" \
  --query "Addresses[*].AllocationId" \
  --output text)

for ALLOC_ID in $ALLOC_IDS; do
  ASSOC_ID=$(aws ec2 describe-addresses \
    --region $REGION \
    --allocation-ids $ALLOC_ID \
    --query "Addresses[0].AssociationId" \
    --output text)
    
  if [ "$ASSOC_ID" != "None" ]; then
    aws ec2 disassociate-address --region $REGION --association-id $ASSOC_ID
  fi

  aws ec2 release-address --region $REGION --allocation-id $ALLOC_ID
done

# Delete security group (if not in use)
SG_IDS=$(aws ec2 describe-security-groups \
  --region $REGION \
  --filters "Name=group-name,Values=$TAG_NAME-sg" \
  --query "SecurityGroups[*].GroupId" \
  --output text)

if [ -n "$SG_IDS" ]; then
  echo "Deleting Security Group(s): $SG_IDS"
  aws ec2 delete-security-group --region $REGION --group-id $SG_IDS
fi

# Delete key pair
aws ec2 delete-key-pair --region $REGION --key-name $KEY_NAME
rm -f "${KEY_NAME}.pem"

echo "Deleted all resources tagged as '$TAG_NAME'"
