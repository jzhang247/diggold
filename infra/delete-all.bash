#!/bin/bash

# Namespaces to clean
NAMESPACES=("default" "my-app")

# Resource types to delete
RESOURCES=(
  deployments
  services
  pods
  jobs
  configmaps
  secrets
  replicasets
  statefulsets
  daemonsets
  cronjobs
  pvc
  ingress
)

for ns in "${NAMESPACES[@]}"; do
  for res in "${RESOURCES[@]}"; do
    echo "Deleting $res in $ns..."
    kubectl delete $res --all -n "$ns" 2>/dev/null
  done
done

