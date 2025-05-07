#!/bin/bash

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.14.2/cert-manager.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.10.0/deploy/static/provider/aws/deploy.yaml
kubectl apply -f "./prod-cluster-issuer.yml"




sleep 15
kubectl apply -f "./prod-ingress.yml"
./add-route53-record-eks.bash


