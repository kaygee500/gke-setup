
# Clean up 
It is good to clean up the infrastructure once you are done to avoid unessary charges

  ## 1. Delete GKE Cluster
``` Shell
gcloud container clusters delete demo-gke --region us-central1  --quiet
```

  ## 2. Delete the firewall rule
``` Shell
gcloud compute firewall-rules delete gke-webapps --quiet
```
echo "--------------------------------------------------------------------"
echo "|......... You've completed the lab. Congratulations!!! ...........|" 
echo "--------------------------------------------------------------------"

echo "------------------------     THE END     -----------------------------"