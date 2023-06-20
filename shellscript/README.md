# Step 1: Execute the script `01.gkesetup.sh`
### Cluster validation steps:
a. Verify the  GKE cluster information
``` Shell 
gcloud container clusters describe  demo-gke --region=us-central1
```

b.  Connect to the cluster using  we need to download the cluster kubeconfig to our location workstation.
``` Shell
gcloud container clusters get-credentials demo-gke  --region=us-central1
```
This generates the kubeconfig and adds it to the ~/.kube/config file. You can also get the connect command from the GKE GUI(i.e. the Cloud Console).


# Step 2: Execute the scripts in the following order:
- 02.testapp.sh
 
a.  Check the deployment status.
``` Shell
kubectl get deployments -n demo
```
b. Check the Pods status
``` Shell
kubectl get pods -n demo
```

c. Describe the service and check the nodePort details.
``` Shell
kubectl describe svc nginx-service -n demo
```
# Step 3: Execute the scripts in the following order:
- 03.firewall.sh
- 04.loadbalancer
- 05.cleanup