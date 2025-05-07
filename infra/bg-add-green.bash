#!/bin/bash

GREEN_VERSION=$1
source versions.env

# FRONTEND
if ! ./is-same-image.bash frontend $FRONTEND_BLUE $GREEN_VERSION; then
  echo "Deploying frontend-green with version $GREEN_VERSION"
  cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: frontend-green
spec:
  replicas: 1
  selector:
    matchLabels:
      app: frontend-green
  template:
    metadata:
      labels:
        app: frontend-green
    spec:
      containers:
      - name: frontend
        image: 932103114236.dkr.ecr.us-east-1.amazonaws.com/frontend:$GREEN_VERSION
        ports:
        - containerPort: 5173
EOF
  FRONTEND_GREEN=$GREEN_VERSION
fi

# BACKEND
if ! ./is-same-image.bash backend $BACKEND_BLUE $GREEN_VERSION; then
  echo "Deploying backend-green with version $GREEN_VERSION"
  cat <<EOF | kubectl apply -f -
apiVersion: apps/v1
kind: Deployment
metadata:
  name: backend-green
spec:
  replicas: 1
  selector:
    matchLabels:
      app: backend-green
  template:
    metadata:
      labels:
        app: backend-green
    spec:
      containers:
      - name: backend
        image: 932103114236.dkr.ecr.us-east-1.amazonaws.com/backend:$GREEN_VERSION
        ports:
        - containerPort: 3000
        env:
        - name: MYSQL_HOST
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: MYSQL_HOST
        - name: MYSQL_USER
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: MYSQL_USER
        - name: MYSQL_PASSWORD
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: MYSQL_PASSWORD
        - name: MYSQL_DATABASE
          valueFrom:
            secretKeyRef:
              name: mysql-secret
              key: MYSQL_DATABASE
EOF
  BACKEND_GREEN=$GREEN_VERSION
fi

cat > versions.env <<EOF
BACKEND_ACTIVE_COLOR=$BACKEND_ACTIVE_COLOR
BACKEND_BLUE=$BACKEND_BLUE
BACKEND_GREEN=$BACKEND_GREEN
FRONTEND_ACTIVE_COLOR=$FRONTEND_ACTIVE_COLOR
FRONTEND_BLUE=$FRONTEND_BLUE
FRONTEND_GREEN=$FRONTEND_GREEN
EOF
