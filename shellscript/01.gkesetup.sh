#!/bin/bash

echo "--------------------- DEMO-GKE CLUSTER --------------------------"

echo ""
echo "------------------------------------------------------------------"
echo "|Creating VPC Network & pod and service secondary range networks.|" 
echo "------------------------------------------------------------------"
gcloud compute networks create gke-network --subnet-mode=custom
echo " ..... VPC Created .....!"

echo ""
echo "--------------------------------------------------------------------------------------------------"
echo "Create a subnet named gke-subnet-a with two secondary ranges named pod-network & service-network|"
echo "--------------------------------------------------------------------------------------------------" 
gcloud compute networks subnets create gke-subnet-a \
    --network gke-network \
    --region us-central1 \
    --range 10.0.1.0/24 \
    --secondary-range pod-network=172.16.0.0/18,service-network=172.16.64.0/20
echo "...... POD & Services Secondary N/W Created .......!"

echo ""
echo "----------------------------------------------------------------"
echo "|Setting Up Kubernetes Cluster On Google Cloud                |"              
echo "----------------------------------------------------------------"
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

echo "--------------------- CLUSTER CREATED --------------------------"
echo " "
echo "----------------- Refer to README for next steps --------------------------"
echo " "