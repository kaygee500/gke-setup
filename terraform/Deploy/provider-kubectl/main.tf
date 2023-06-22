data "google_client_config" "default" {}

provider "kubernetes" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

provider "kubectl" {
  host                   = "https://${module.gke.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.ca_certificate)
}

module "gke_auth" {
  source = "terraform-google-modules/kubernetes-engine/google//modules/auth"
  version = "24.1.0"
  depends_on   = [module.gke]
  project_id   = var.project_id
  location     = module.gke.location
  cluster_name = module.gke.name
}

resource "local_file" "kubeconfig" {
  content  = module.gke_auth.kubeconfig_raw
  filename = "kubeconfig-${var.env_name}"
}

module "gcp-network" {
  source       = "terraform-google-modules/network/google"
  version      = "6.0.0"
  project_id   = var.project_id
  network_name = "${var.network}-${var.env_name}"

  subnets = [
    {
      subnet_name   = "${var.subnetwork}-${var.env_name}"
      subnet_ip     = "10.0.1.0/24"
      subnet_region = var.region
    },
  ]

  secondary_ranges = {
    "${var.subnetwork}-${var.env_name}" = [
      {
        range_name    = var.ip_range_pods_name
        ip_cidr_range = "172.16.0.0/18"
      },
      {
        range_name    = var.ip_range_services_name
        ip_cidr_range = "172.16.64.0/20"
      },
    ]
  }
}

module "gke" {
  source                            = "terraform-google-modules/kubernetes-engine/google//modules/private-cluster"
  version                           = "24.1.0"
  project_id                        = var.project_id
  name                              = "${var.kubernetes_cluster_name}-${var.env_name}"
  regional                          = true
  region                            = var.region
  network                           = module.gcp-network.network_name
  subnetwork                        = module.gcp-network.subnets_names[0]
  ip_range_pods                     = var.ip_range_pods_name
  ip_range_services                 = var.ip_range_services_name
  create_service_account            = false
  remove_default_node_pool          = true
  disable_legacy_metadata_endpoints = false

  node_pools = [
    {
      name                      = "node-pool"
      machine_type              = "g1-small"
      node_locations            = "europe-west2-b,europe-west2-c,europe-west2-a"
      min_count                 = 1
      max_count                 = 3
      disk_type                 = "pd-standard"
      disk_size_gb              = 50
      preemptible               = true
      auto_repair               = false
      auto_upgrade              = true
    },
  ]
  
  node_pools_tags = {
    all = [
        "gke-webapps"
    ]
  }

}

#"---------- Deploying app in the demo namespace --------"
resource "kubernetes_namespace" "demo" {
  metadata {
    name = "demo"
  }
}

#---------- Deploying app in the demo namespace --------"
resource "kubectl_manifest" "nginx_deployment"{
  yaml_body = <<YAML
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
YAML
}


# ----- Expose app on Nodeport -------------
resource "kubectl_manifest" "nginx_service_np" {
  yaml_body = <<YAML
apiVersion: v1
kind: Service
metadata:
  name: nginx-service-np
  namespace: demo
spec:
  selector:
    app: nginx
  type: NodePort
  ports:
    - port: 80
      targetPort: 80
      nodePort: 32000
YAML
}


#"--------------------- FIREWALL RULE  --------------------------"
resource "google_compute_firewall" "rules" {
  project     = var.project_id
  name        = "gke-webapps"
  network     = module.gcp-network.network_name
  description = "Allow incoming traffic on TCP port 32000"

  allow {
    protocol  = "tcp"
    ports     = ["32000"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags = ["gke-webapps"]
}

#--------------------- LOADBALANCER SERVICE  --------------------------"
resource "kubectl_manifest" "nginx_servic_lb" {
  yaml_body = <<YAML
    apiVersion: v1
    kind: Service
    metadata:
      name: nginx-service-lb
      namespace: demo
    spec:
      selector:
        app: nginx
      type: LoadBalancer
      ports:
      - port: 80
        targetPort: 80
  YAML
}