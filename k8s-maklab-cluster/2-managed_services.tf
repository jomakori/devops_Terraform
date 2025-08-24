# /* 
#   ┌──────────────────────────────────────────────────────────────────────────┐
#   │ GitOps: Setup ArgoCD - ArgoCD can't manage itself                        │
#   │ Used for syncing Apps + Services from the GitOps Repo                    │
#   └──────────────────────────────────────────────────────────────────────────┘
#  */
# resource "helm_release" "argocd" {
#   namespace        = "argocd"
#   create_namespace = true

#   name       = "argo-cd"
#   chart      = "argo-cd"
#   repository = "https://argoproj.github.io/argo-helm"
#   values     = [file("helm/argocd-values.yaml")]

#   depends_on = [minikube_cluster.maklab_cluster]
# }

