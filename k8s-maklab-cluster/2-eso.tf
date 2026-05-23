# Centralized ESO ClusterSecretStore

resource "kubectl_manifest" "eso_namespace" {
  yaml_body = <<YAML
apiVersion: v1
kind: Namespace
metadata:
  name: external-secrets
YAML

  depends_on = [minikube_cluster.maklab_cluster]
}

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
  dopplerToken: ${var.DOPPLER_TOKEN}
YAML
  force_new  = true
  depends_on = [kubectl_manifest.eso_namespace]
}
