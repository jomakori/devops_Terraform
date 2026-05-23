# bootstrap Doppler service account + machine token that ESO ClusterSecretStores use.
# Configs (svc_grafana, svc_mongodb, svc_postgres, svc_cloudflare) already exist in devops project.

resource "kubernetes_namespace_v1" "eso" {
  metadata {
    name = "external-secrets"
  }
  lifecycle {
    ignore_changes = all
  }
  depends_on = [minikube_cluster.maklab_cluster]
}

# Service account at workplace level
resource "doppler_service_account" "k8s_eso" {
  name           = "k8s-eso-sa"
  workplace_role = "collaborator"
}

# Grant project-level read access to devops project
resource "doppler_project_member_service_account" "devops" {
  project              = "devops"
  service_account_slug = doppler_service_account.k8s_eso.slug
  role                 = "viewer"
}

resource "doppler_service_account_token" "eso_token" {
  service_account_slug = doppler_service_account.k8s_eso.slug
  name                 = "eso-machine-token"
  expires_at           = timeadd(plantimestamp(), "2160h")
}

# centralized service token for eso
## Note: Access scoping to specific configs - is set via helm templating in gitops repo
resource "kubectl_manifest" "doppler_machine_token_secret" {
  yaml_body  = <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: doppler-machine-token
  namespace: external-secrets
  labels:
    app.kubernetes.io/managed-by: terraform
type: Opaque
stringData:
  dopplerToken: ${doppler_service_account_token.eso_token.api_key}
YAML
  force_new  = true
  depends_on = [kubernetes_namespace_v1.eso]
}
