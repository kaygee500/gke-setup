data "google_client_config" "default" {}

provider "kubernetes" {
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

#"---------- Deploying app in the demo namespace --------"
resource "kubernetes_deployment" "nginx_deployment" {
  metadata {
    name = "nginx-deployment"
    namespace = kubernetes_namespace.demo.metadata[0].name
  }

  spec {
    replicas = 2

    selector {
      match_labels = {
        app = "nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }

      spec {
        container {
          image = "nginx:latest"
          name  = "nginx"
          port {
            container_port = 80            
          }
        }
      }
    }
  }
}

#"......... Expose app on Nodeport ........!"
resource "kubernetes_service" "nginx_service" {
  metadata {
    name      = "nginx-service"
    namespace = kubernetes_namespace.demo.metadata[0].name
  }
  spec {
    selector = {
      app = "nginx"
    }
    port {
      port        = 80
      node_port = 32000
    }
    type             = "NodePort"
  }
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
resource "kubernetes_service" "nginx_service" {
  metadata {
    namespace = kubernetes_namespace.demo.metadata[0].name
    name      = "nginx-service-lb"
  }
  spec {
    selector = {
     app = "nginx"
    }
    session_affinity = "ClientIP"
    port {
      protocol    = "TCP"
      port        = 80
      target_port = 80
    }
    type = "LoadBalancer"

 }
}