output "kubeconfig" {
  description = "Kubeconfig for accessing the minikube cluster via Tailscale tunnel"
  sensitive   = true
  value = yamlencode({
    apiVersion        = "v1"
    kind              = "Config"
    "current-context" = var.name
    clusters = [
      {
        name = var.name
        cluster = {
          server                       = "https://${var.name}.${var.TAILSCALE_TUNNEL}:8443"
          "certificate-authority-data" = base64encode(minikube_cluster.maklab_cluster.cluster_ca_certificate)
        }
      }
    ]
    contexts = [
      {
        name = var.name
        context = {
          cluster = var.name
          user    = var.name
        }
      }
    ]
    users = [
      {
        name = var.name
        user = {
          "client-certificate-data" = base64encode(minikube_cluster.maklab_cluster.client_certificate)
          "client-key-data"         = base64encode(minikube_cluster.maklab_cluster.client_key)
        }
      }
    ]
  })
}
