GKE has two types of clusters.

Autopilot Cluster: All cluster infrastructure operations are taken care of by Google cloud. You just have to focus on application deployments.

Standard Cluster: Here except for the control plane, you have to manage the underlying infrastructure (Nodes, scaling etc)
Following image shows the main difference between autopilot and standard GKE cluster.

There are two types of standard GKE cluster.

Public GKE cluster: Control plane node is publicly accessible, and all the worker nodes have a public interface attached to them. Here the cluster is secured using firewall rules and whitelisting only approved IP ranges to connect to the cluster API. This reduces the attack surface. The public clusters are normally not part of an organization’s hybrid network due to the fact that the nodes have a public interface.

Private GKE Cluster: The control plan and worker nodes get deployed in a predefined VPC network range defined by the user. The access to the cluster components will be completely private through VPC networks. Even though the control plane gets launched in the CIDR given by the user, that VPC gets created and managed by google cloud. We can only control the worker node subnets.

The cluster can be setup manually using the steps in ./manual file. Alternatively you can automate the creation ./02.shell or ./03.terraform. 