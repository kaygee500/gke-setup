#! /bin/bash
echo "--------------------- FIREWALL RULE  --------------------------"

echo ""
echo "............... Creating a firewall rule to access the app .....!                       |" 
gcloud compute firewall-rules create gke-webapps \
    --network=gke-network \
    --allow=tcp:32000 \
    --description="Allow incoming traffic on TCP port 32000" \
    --direction=INGRESS \
    --source-ranges="0.0.0.0/0" \
    --target-tags="gke-webapps"

echo "--------------------- FIREWALL RULE CREATED --------------------------"

echo "........... Retrieving External IPs of Nodes .......................!"
gcloud compute instances list --filter="name~'gke-demo-*'"

echo ""
echo "--------------------------------------------------------------------"
echo "|Goto <http://A Node's External IP>:32000 to access the Nginx page|" 
echo "--------------------------------------------------------------------"

echo " "
echo "--------------------- NEXT execute 04.loadbalancer.sh --------------------------"
echo " "