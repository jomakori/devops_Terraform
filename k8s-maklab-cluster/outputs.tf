locals {
  cluster_name   = minikube_cluster.maklab_cluster.cluster_name
  tailscale_fqdn = "${var.name}.${var.TAILSCALE_HOST}"
}

output "kubeconfig" {
  description = "Kubeconfig for accessing the minikube cluster via Tailscale tunnel"
  sensitive   = true
  value       = <<-EOF
apiVersion: v1
kind: Config
current-context: ${local.cluster_name}
clusters:
- name: ${local.cluster_name}
  cluster:
    server: https://${local.tailscale_fqdn}:443
    certificate-authority-data: "${base64encode(minikube_cluster.maklab_cluster.cluster_ca_certificate)}"
contexts:
- name: ${local.cluster_name}
  context:
    cluster: ${local.cluster_name}
    user: ${local.cluster_name}
users:
- name: ${local.cluster_name}
  user:
    client-certificate-data: "${base64encode(minikube_cluster.maklab_cluster.client_certificate)}"
    client-key-data: "${base64encode(minikube_cluster.maklab_cluster.client_key)}"
EOF
}
