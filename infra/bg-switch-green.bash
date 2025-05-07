#!/bin/bash
source versions.env

if [ -n "$FRONTEND_GREEN" ]; then
  echo "Switching frontend service to green"
  kubectl patch service frontend -p '{"spec":{"selector":{"app":"frontend-green"}}}'
  FRONTEND_ACTIVE_COLOR=green
fi

if [ -n "$BACKEND_GREEN" ]; then
  echo "Switching backend service to green"
  kubectl patch service backend -p '{"spec":{"selector":{"app":"backend-green"}}}'
  BACKEND_ACTIVE_COLOR=green
fi

cat > versions.env <<EOF
BACKEND_ACTIVE_COLOR=$BACKEND_ACTIVE_COLOR
BACKEND_BLUE=$BACKEND_BLUE
BACKEND_GREEN=$BACKEND_GREEN
FRONTEND_ACTIVE_COLOR=$FRONTEND_ACTIVE_COLOR
FRONTEND_BLUE=$FRONTEND_BLUE
FRONTEND_GREEN=$FRONTEND_GREEN
EOF
