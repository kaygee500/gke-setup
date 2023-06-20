#!/bin/bash

echo "---------------------  CLEAN-UP  --------------------------"
echo ""
echo "................ Deleting GKE Cluster ............!" 
  ## 1. Delete GKE Cluster
``` Shell
gcloud container clusters delete demo-gke --region us-central1  --quiet
```
echo "--------------------- CLUSTER DELETED ----------------------"

echo ""
echo "................ Deleting firewall rule ............!" 

``` Shell
gcloud compute firewall-rules delete gke-webapps --quiet
```
echo "----------------- FIREWALL RULE DELETED  --------------------"

echo ""
echo ""
echo "--------------------------------------------------------------------"
echo "|......... You've completed the lab. Congratulations!!! ...........|" 
echo "--------------------------------------------------------------------"

echo "------------------------   THE END     -----------------------------"