#!/bin/bash

echo "---------------------  CLEAN-UP  --------------------------"
echo ""
echo "................ Deleting GKE Cluster ............!" 

gcloud container clusters delete demo-gke --region us-central1  --quiet

echo "--------------------- CLUSTER DELETED ----------------------"

echo ""
echo "................ Deleting firewall rule ............!" 

gcloud compute firewall-rules delete gke-webapps --quiet

echo "----------------- FIREWALL RULE DELETED  --------------------"

echo ""
echo "................  Deleting the network   ............!" 

gcloud compute networks delete gke-network --quiet

echo "-----------------   NETWORK DELETED   --------------------"

echo ""
echo ""
echo "--------------------------------------------------------------------"
echo "|......... You've completed the lab. Congratulations!!! ...........|" 
echo "--------------------------------------------------------------------"

echo "------------------------   THE END     -----------------------------"