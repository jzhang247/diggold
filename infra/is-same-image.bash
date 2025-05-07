#!/bin/bash

# Usage: ./check_ecr_image_tags.sh <repository_name> <tag1> <tag2> [--region region-name]

REPO_NAME=$1
TAG1=$2
TAG2=$3
REGION=${4:-}  # Optional: --region us-east-1

if [[ -z "$REPO_NAME" || -z "$TAG1" || -z "$TAG2" ]]; then
  echo "Usage: $0 <repository_name> <tag1> <tag2> [--region region-name]"
  exit 1
fi

# Get image digests for each tag
DIGEST1=$(aws ecr describe-images --repository-name "$REPO_NAME" --image-ids imageTag="$TAG1" $REGION --query 'imageDetails[0].imageDigest' --output text 2>/dev/null)
DIGEST2=$(aws ecr describe-images --repository-name "$REPO_NAME" --image-ids imageTag="$TAG2" $REGION --query 'imageDetails[0].imageDigest' --output text 2>/dev/null)

# Compare digests and print result
if [[ -z "$DIGEST1" || -z "$DIGEST2" ]]; then
  echo "invalid"
  exit 1
fi

if [[ "$DIGEST1" == "$DIGEST2" ]]; then
  echo "same"
  exit 0
else
  echo "different"
  exit 1
fi
