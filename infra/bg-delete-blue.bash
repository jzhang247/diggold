#!/bin/bash
source versions.env

# FRONTEND
if [ "$FRONTEND_ACTIVE_COLOR" == "green" ] && [ -n "$FRONTEND_GREEN" ]; then
  echo "Deleting frontend-blue"
  kubectl delete deployment frontend-blue
  FRONTEND_BLUE=$FRONTEND_GREEN
  FRONTEND_GREEN=
fi

# BACKEND
if [ "$BACKEND_ACTIVE_COLOR" == "green" ] && [ -n "$BACKEND_GREEN" ]; then
  echo "Deleting backend-blue"
  kubectl delete deployment backend-blue
  BACKEND_BLUE=$BACKEND_GREEN
  BACKEND_GREEN=
fi

cat > versions.env <<EOF
BACKEND_ACTIVE_COLOR=$BACKEND_ACTIVE_COLOR
BACKEND_BLUE=$BACKEND_BLUE
BACKEND_GREEN=$BACKEND_GREEN
FRONTEND_ACTIVE_COLOR=$FRONTEND_ACTIVE_COLOR
FRONTEND_BLUE=$FRONTEND_BLUE
FRONTEND_GREEN=$FRONTEND_GREEN
EOF
