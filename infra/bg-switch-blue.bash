#!/bin/bash
source versions.env

echo "Switching services back to blue"

kubectl patch service frontend -p '{"spec":{"selector":{"app":"frontend-blue"}}}'
kubectl patch service backend -p '{"spec":{"selector":{"app":"backend-blue"}}}'

FRONTEND_ACTIVE_COLOR=blue
BACKEND_ACTIVE_COLOR=blue

cat > versions.env <<EOF
BACKEND_ACTIVE_COLOR=$BACKEND_ACTIVE_COLOR
BACKEND_BLUE=$BACKEND_BLUE
BACKEND_GREEN=$BACKEND_GREEN
FRONTEND_ACTIVE_COLOR=$FRONTEND_ACTIVE_COLOR
FRONTEND_BLUE=$FRONTEND_BLUE
FRONTEND_GREEN=$FRONTEND_GREEN
EOF
