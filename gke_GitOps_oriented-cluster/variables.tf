/* 
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ Project variables                                                        │
  └──────────────────────────────────────────────────────────────────────────┘
 */
variable "project_id" {
  description = "Google Account/Project ID"
  default     = "absolute-cipher-449014-p0"
}
variable "region" {
  description = "GCP region for resources"
  default     = "us-central1" # 4 azs
}

/* 
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ Workspace variables                                                      │
  └──────────────────────────────────────────────────────────────────────────┘
 */
variable "name" {
  description = "Namespace for workspace resources"
  default     = "gitops-k8s-cluster"
}
variable "subnet_cidr_ranges" {
  description = "Mapping of CIDR ranges for VPC networking"
  type        = map(string)
  default = {
    "subnet-a" = "10.0.0.0/16"
    "subnet-b" = "10.1.0.0/16"
  }
}

variable "k8s_cidr_ranges" {
  description = "Mapping of CIDR ranges for K8s pods + services"
  type        = map(any)
  default = {
    "pods"          = "192.168.0.0/16"
    "services"      = "192.169.0.0/16"
    "control-plane" = "172.16.0.0/28"
  }
}
