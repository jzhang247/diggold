#!/bin/bash

# Ensure required environment variables are set
: "${DOMAIN:?Environment variable DOMAIN (e.g. example.com) is required}"
: "${EC2_NAME:?Environment variable EC2_NAME (e.g. server-qa) is required}"
: "${RECORD_NAME:?Environment variable RECORD_NAME (e.g. server-qa.example.com.) is required}"

# Step 1: Find Hosted Zone ID by domain name
HOSTED_ZONE_ID=$(aws route53 list-hosted-zones-by-name \
    --dns-name "$DOMAIN" \
    --query "HostedZones[?Name=='${DOMAIN}.'].Id" \
    --output text | cut -d'/' -f3)

if [ -z "$HOSTED_ZONE_ID" ]; then
    echo "Hosted zone for domain $DOMAIN not found."
    exit 1
fi

# Step 2: Get instance ID of EC2 with Name tag
INSTANCE_ID=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$EC2_NAME" "Name=instance-state-name,Values=running" \
    --query "Reservations[0].Instances[0].InstanceId" \
    --output text)

if [ "$INSTANCE_ID" == "None" ] || [ -z "$INSTANCE_ID" ]; then
    echo "No running instance found with tag Name=$EC2_NAME"
    exit 1
fi

# Step 3: Get public IP
PUBLIC_IP=$(aws ec2 describe-instances \
    --instance-ids "$INSTANCE_ID" \
    --query "Reservations[0].Instances[0].PublicIpAddress" \
    --output text)

if [ -z "$PUBLIC_IP" ] || [ "$PUBLIC_IP" == "None" ]; then
    echo "Instance found but no public IP available."
    exit 1
fi

# Step 4: Create JSON for Route 53 update
cat > /tmp/route53-record.json <<EOF
{
  "Comment": "Update A record for $RECORD_NAME",
  "Changes": [{
    "Action": "UPSERT",
    "ResourceRecordSet": {
      "Name": "$RECORD_NAME",
      "Type": "A",
      "TTL": 300,
      "ResourceRecords": [{
        "Value": "$PUBLIC_IP"
      }]
    }
  }]
}
EOF

# Step 5: Submit change to Route 53
aws route53 change-resource-record-sets \
    --hosted-zone-id "$HOSTED_ZONE_ID" \
    --change-batch file:///tmp/route53-record.json

echo "Updated $RECORD_NAME to point to $PUBLIC_IP in hosted zone $DOMAIN"
