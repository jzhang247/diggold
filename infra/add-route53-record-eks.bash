#!/bin/bash


# DOMAIN="jzhang247.engineer"
# RECORD_NAME="prod.${DOMAIN}"


echo "Looking up hosted zone ID for $DOMAIN..."
ZONE_ID=$(aws route53 list-hosted-zones-by-name --dns-name "$DOMAIN" --query "HostedZones[0].Id" --output text | cut -d'/' -f3)
if [ -z "$ZONE_ID" ]; then
  echo "Error: Could not find hosted zone for $DOMAIN"
  exit 1
fi
echo "Found Hosted Zone ID: $ZONE_ID"




NAMESPACE="ingress-nginx"
SERVICE_NAME="ingress-nginx-controller"
LB_HOSTNAME=$(kubectl get svc "$SERVICE_NAME" -n "$NAMESPACE" -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
if [ -z "$LB_HOSTNAME" ]; then
  echo "Error: Could not find LoadBalancer hostname"
  exit 1
fi
echo "Found LoadBalancer hostname: $LB_HOSTNAME"


CHANGE_BATCH=$(cat <<EOF
{
  "Comment": "Creating/updating DNS record for $RECORD_NAME",
  "Changes": [
    {
      "Action": "UPSERT",
      "ResourceRecordSet": {
        "Name": "$RECORD_NAME",
        "Type": "CNAME",
        "TTL": 300,
        "ResourceRecords": [
          {
            "Value": "$LB_HOSTNAME"
          }
        ]
      }
    }
  ]
}
EOF
)

echo "Creating Route53 DNS record..."
aws route53 change-resource-record-sets --hosted-zone-id "$ZONE_ID" --change-batch "$CHANGE_BATCH"
echo "DNS record for $RECORD_NAME pointing to $LB_HOSTNAME has been created/updated."
