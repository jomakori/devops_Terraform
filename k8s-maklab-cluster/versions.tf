terraform {

  cloud {
    organization = "tf_jmakori"

    workspaces {
      name = "k8s-maklab-cluster"
    }
  }
  required_providers {
    minikube = {
      source  = "scott-the-programmer/minikube"
      version = ">= 0.6.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = ">= 2.17.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = ">= 1.19.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = ">= 2.22.0"
    }
  }
}

# Minikube
provider "minikube" {
  kubernetes_version = var.kubernetes_version
  # To restrict the Minikube API server/public endpoint to localhost,
  # start your Minikube cluster with:
  # minikube start --apiserver-ips=127.0.0.1 --listen-address=127.0.0.1
  # This cannot be set via the Terraform provider.
}


# Helm
provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
}

# kubectl
provider "kubectl" {
  load_config_file = true
}
