# Step 1: Execute the scripts in the following order:
- 01.gkesetup.sh
- 02.testapp.sh
 
# Step 2: Check the deployment status.
``` Shell
kubectl get deployments -n demo
```

# Step 3: Describe the service and check the nodePort details.
``` Shell
kubectl describe svc nginx-service -n demo
```

# Step 4: Execute the scripts in the following order:
- 03.firewall.sh
- 04.loadbalancer
- 05.cleanup