GKE has two types of clusters.

Autopilot Cluster: All cluster infrastructure operations are taken care of by Google cloud. You just have to focus on application deployments.

Standard Cluster: Here except for the control plane, you have to manage the underlying infrastructure (Nodes, scaling etc)
Following image shows the main difference between autopilot and standard GKE cluster.


Create VPC With GKE Subnet & Secondary IP Ranges
Note: Ensure you have the IAM admin permissions to create the network, GKE cluster, and associated components.

You can create the GKE cluster in the default VPC provided by Google cloud. However, for learning and better understanding, lets create our own VPC.

Normally, when we deploy non-containerized workloads on VPC, we would just create subnets with primarry IP ranges.

When it comes to the GKE cluster, we need to create a subnet to host the cluster nodes, and secondary IP ranges under the subnet for the kubernetes pod and service network. In google cloud term; it is called VPC native clusters.

So, lets plan for nework for the following requirements.

``` Shell
Cluster Requirements	                     Calculated IP ranges
The cluster should accommodate 200 
Nodes. (Primary Subnet)	                     This means we need a subnet with a minimum of 254 IP addresses. That is 10.0.1.0/24

Each node should accommodate 75 pods 
(Secondary range – Pod network)	             200×75 = 15000 . So we will /18 secondary range that would give 16384 IP addresses. 172.16.0.0/18 (172.16.0.0 – 172.16.63.255)

The cluster should support 2000 services. 
Secondary range – Service network)	       Hence we need a /21 range for the service network. Assuming we continue from the pod range, it would be be 172.16.64.0/20 (172.16.64.0 – 172.16.79.255)
```

Finally we have arrived to the following network ranges.

1. Primary subnet (For Cluster Nodes) – 10.0.1.0/24
2. Secondary network (For pods) – 172.16.0.0/18
3. Secondary network (For services) – 172.16.64.0/20

GKE cluster network architecture


So here is what we are going to do.
1. Create a VPC
2. Add a subnet with pod and service secondary range networks.

Now that we have finalized the network ranges let’s create a VPC network. I am calling network name as gke-network

``` Shell
gcloud compute networks create gke-network --subnet-mode=custom
```
Create a subnet named gke-subnet-a with two secondary ranges named pod-network & service-network

```shell 
gcloud compute networks subnets create gke-subnet-a \
    --network gke-network \
    --region us-central1 \
    --range 10.0.1.0/24 \
    --secondary-range pod-network=172.16.0.0/18,service-network=172.16.64.0/20
```
By default the subnet creates a routed to the internet gateway. So you dont have to do anything to enable internet access for the nodes. However, we need to add custom firewall rules to access the nodes from outside the VPC network.

Note: When running production workloads, careful consideration has been given to the network design by keeping the subnets fully private without internet gateways.

Now we have the necessary network infrastructure to deploy a public GKE cluster.

Setting Up Kubernetes Cluster On Google Cloud

Note: If you are looking for a self-hosted test/POC kubernetes cluster setup on google cloud, you can use Kubeadm to quickly configure it. Refer to my Kubeadm cluster setup guide for setting up one master node and multi worker node Kubernetes setup.

There are two types of standard GKE cluster.

Public GKE cluster: Control plane node is publicly accessible, and all the worker nodes have a public interface attached to them. Here the cluster is secured using firewall rules and whitelisting only approved IP ranges to connect to the cluster API. This reduces the attack surface. The public clusters are normally not part of an organization’s hybrid network due to the fact that the nodes have a public interface.

Private GKE Cluster: The control plan and worker nodes get deployed in a predefined VPC network range defined by the user. The access to the cluster components will be completely private through VPC networks. Even though the control plane gets launched in the CIDR given by the user, that VPC gets created and managed by google cloud. We can only control the worker node subnets.


Prerequitests
You should have gcloud configured from the machine you are trying to set up the cluster. Refer to google cloud SDK setup guide to configure gcloud
If you are using google cloud servers, gcloud is available by default. You should have the admin service account attached to the server for provisioning GKE services.
GKE Cluster Creation Using gcloud CLI

Step 1: We will use the gcloud CLI to launch a regional multi-zone cluster.

In our setup, we will be doing the following.

Spin up the cluster in us-central1 the region with one instance per zone (total three zones) using g1-small(1.7GB) machine type with autoscaling enabled.
Preemptible VMs with autoscaling to a maximum of three-node per to reduce the cost of the cluster.
Cluster gets deployed with custom VPC, subnets & secondary ranges we created in the previous section.
Enable the master authorized network to allow only whitelisted IP ranges to connect to the master API. I have given 0.0.0.0/0, you can replace this with your IP address.
Add a network tag named “webapps” to add a custom firewall rule to the GKE cluster nodes for testing purposes.
Note: When deploying a cluster in production, more configurations need to be considered for the network and the cluster. It depends on the organizational policy and project requirements.

Now, lets create the cluster using the following command.

``` shell
gcloud container clusters create demo-gke \
      --region us-central1 \
      --no-enable-ip-alias \
      --node-locations us-central1-a,us-central1-b,us-central1-c \
      --num-nodes 1 \
      --enable-autoscaling \
      --min-nodes 1 \
      --max-nodes 3 \
      --node-labels=env=dev \
      --machine-type g1-small \
      --enable-autorepair  \
      --node-labels=type=webapps \
      --enable-vertical-pod-autoscaling \
      --preemptible \
      --disk-type pd-standard \
      --disk-size 50 \
      --enable-ip-alias \
      --network gke-network \
      --subnetwork gke-subnet-a \
      --cluster-secondary-range-name pod-network \
      --services-secondary-range-name service-network \
      --tags=gke-webapps \
      --enable-master-authorized-networks \
      --master-authorized-networks=0.0.0.0/0
```

Step 2: You can get all the information about the  GKE cluster using the following command.

``` Shell 
gcloud container clusters describe  demo-gke --region=us-central1
```

Step 3: Now, we need to download the cluster kubeconfig to our location workstation.

The following command generates the kubeconfig and adds it to the ~/.kube/config file.

``` Shell
gcloud container clusters get-credentials demo-gke  --region=us-central1
```
You can also get the connect command from the GKE GUI.

Now, you can get your cluster information using the kubectl command using the following command.
``` Shell
kubectl cluster-info
```

Deploy Nginx on GKE for Validation
Let’s deploy a sample Nginx application in a custom namespace to validate the cluster.

Step 1: Create a namespace named demo
``` Shell
kubectl create namespace demo
```

Step 2: Let’s deploy a sample Nginx app in the demo namespace. Also, create a Nodeport service for testing purposes.
``` Shell
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
```

Lets check the deployment status.
``` Shell
kubectl get deployments -n demo
```
Also lets describe the service and check the nodePort details.
``` Shell
kubectl describe svc nginx-service -n demo
```
Step 3: Now to access the application on node port 32000, you need to add an ingress firewall rule to allow traffic on port 32000 from the internet.

This rule is applicable for all instances with gke-webapps tag in gke-network
``` Shell
gcloud compute firewall-rules create gke-webapps \
    --network=gke-network \
    --allow=tcp:32000 \
    --description="Allow incoming traffic on TCP port 32000" \
    --direction=INGRESS \
    --source-ranges="0.0.0.0/0" \
    --target-tags="gke-webapps"
```

For demonstration purposes, I am adding 0.0.0.0/0 as the source IP range. Meaning, allow traffic from anywhere on the internet. You can get your public IP by a simple google search and add it as a source instead of 0.0.0.0/0

Step 5: Now that we have added the rule, lets try accessing the Nginx app using a nodes IP.

The following command will list all GKE nodes with their public IP address. Grab one IP and try accessing port 32000 and see if you can access the Nginx page.
``` Shell
gcloud compute instances list --filter="name~'gke-demo-*'"
```

Expose Nginx as a Loadbalancer Service
The same deployment can be exposed as a Loadbalancer by modifying the NodePort to Loadbalancer in the service file. GKE will create a Loadbancer that points to the Nginx service endpoint.
``` Shell
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
```
Delete GKE Cluster
If you want to delete the GKE cluster, use the following command.
``` Shell
gcloud container clusters delete demo-gke --region us-central1  --quiet
```
Also, to remove the firewall rule, execute the following command.
``` Shell
gcloud compute firewall-rules delete gke-webapps --quiet
```
Conclusion
Setting up a Kubernetes cluster on google cloud is an easy task. However, many configurations need to be considered for production setup from a security, scalability, and network standpoint.