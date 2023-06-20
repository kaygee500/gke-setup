#!/bin/bash
echo "--------------------- LOADBALANCER SERVICE  --------------------------"

echo "............. Exposing Nginx as a Loadbalancer Service ................!"
cat << EOF | kubectl apply -f -
apiVersion: v1
kind: Service
metadata:
  name: nginx-service
  namespace: demo
spec:
  selector:
    app: nginx
  type: LoadBalancer
  ports:
    - port: 80
      targetPort: 80
EOF

echo "--------------------- LOADBALANCER CREATED  --------------------------"
echo ""
echo "------------------------------------------------------------------"
echo "|Goto <http://Loadbalncer External IP>:80 access Nginx Page     | " 
echo "------------------------------------------------------------------"

echo " "
echo "--------------------- NEXT execute 05.cleanup.sh --------------------------"
echo " "