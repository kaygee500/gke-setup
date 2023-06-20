#!/bin/bash

echo "--------------------- TESTAPP --------------------------"

echo "---------------------------------------"
echo "|Deployin Nginx on GKE for Validation    |"
echo "---------------------------------------"

echo "........... Creating demo namespace .........!"
kubectl create namespace demo

echo " "
echo "......... Deploying app in the demo namespace & Expose on Nodeport ........!"

cat <<EOF | kubectl apply -f -
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-deployment
  namespace: demo
spec:
  selector:
    matchLabels:
      app: nginx
  replicas: 2 
  template:
    metadata:
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx:latest
        ports:
        - containerPort: 80
---
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  namespace: demo
spec:
  selector:
    app: nginx
  type: NodePort
  ports:
    - port: 80
      targetPort: 80
      nodePort: 32000
EOF

echo "--------------------- TESTAPP DEPLOYED--------------------------"

echo " "
echo "--------------------- Refer to README --------------------------"
echo " "