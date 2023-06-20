# Google Kubernetes Engine (GKE) Setup

## What is GKE?
Google Kubernetes Engine(GKE) is a Google's implementation of the Kubernetes open source container orchestration platform. GKE has two types of clusters. GKE is ideal if you need a platform that lets you configure the infrastructure that runs your containerized apps, such as networking, scaling, hardware, and security. 

#### Modes of operation
GKE clusters can be created using the following modes of operation. This determines the level of control you want with your cluster.

* Autopilot Cluster: All cluster infrastructure management and operations are taken care of by Google Cloud. Customer focus here is on application deployments. 

* Standard Cluster: Google Cloud manges the control plane whilst the customer manages the underlying infrastructure (Nodes, scaling etc)

![Autopilot vs Standard](./img/clustermode.png)

Main differences between the cluster mode is below. 

Refer to [GKE Cluster Mode](https://cloud.google.com/kubernetes-engine/docs/concepts/cluster-architecture?_ga=2.208064722.-1396940121.1686217398) for more information.

#### Network isolation choices
These determin how your cluster's workloads are accessed over the networks. Routes are not created automatically.

* Public GKE cluster: Control plane node is publicly accessible, and all the worker nodes have a public interface attached to them. In a production environment, exta care must be taken to protect your envionrment. For example, using firewall rules and whitelisting only IP ranges that connect to the cluster API. Other controls will be need to secure your workloads and cluster. Hence, public clusters are normally not part of an organization’s hybrid network due to the fact that the nodes have a public interface.

* Private GKE Cluster: The worker nodes and pods are assinged internal IP address, hence not accesible over the internet. The access to the cluster components will be completely private through VPC networks. Access to the internet may require a Cloud NAT

`Note:` _You can undo these settings once the cluster is created._

The cluster can be setup manually using the steps in ./manual file. Alternatively you can automate the creation ./02.shell or ./03.terraform. 
## 4 Ways for creating a GKE cluster
### Assumptions:
This tutorial assumes that you have enabled the necessary APIs(i.e. GKE API)

1. Cloud Console: a simple web-based graphical user interface helps you create and manage projects and resources. You can deploy, scale, and diagnose production issues with the console. To learn more about the console refer to [cloud-console](https://cloud.google.com/cloud-console) 

2. Mannual Steps:
The manual steps invole the sequence of `commands` in ./manual/gkesetup.md using either [Cloud Shell](https://cloud.google.com/shell) or [Cloud SDK](https://cloud.google.com/sdk). 

## Conclusion
It is easy to set uo a GKE cluster. In the real world many configurations from a security, scalability, and networking need to be considered. For more details refer to [GKE Security Concepts](https://cloud.google.com/kubernetes-engine/docs/concepts/security-overview).

## Acknowldgements 
This project was based on [this tutorial](https://devopscube.com/setup-kubernetes-cluster-google-cloud/)