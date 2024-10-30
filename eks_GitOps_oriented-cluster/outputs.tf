output "configure_kubectl" {
  description = "Configure kubectl: make sure you're logged into AWScli w/ SSO and run the following command to update your kubeconfig"
  value       = <<-EOT
    NOTE: COPY AND PASTE BELOW TO TERMINAL FOR RESULTS
    echo "Adding cluster to kubeconfig..."
    aws eks --region ${var.region} update-kubeconfig --name ${module.eks.eks_cluster_id}
  EOT
}

output "access_argocd" {
  description = "ArgoCD Access"
  value       = <<-EOT
    NOTE: COPY AND PASTE BELOW TO TERMINAL FOR RESULTS
    echo "ArgoCD Username: admin"
    echo "ArgoCD Password: $(kubectl get secrets argocd-initial-admin-secret -n argocd --template="{{index .data.password | base64decode}}")"
    echo "ArgoCD URL: argocd.intc.net"
    echo "ArgoCD LB: $(kubectl get svc argo-cd-argocd-server -n argocd -o json | jq --raw-output '.status.loadBalancer.ingress[0].hostname')"
    EOT
}
