# Doppler Access Token Secret
resource "kubectl_manifest" "doppler_machine_token_secret" {
  yaml_body  = <<YAML
apiVersion: v1
kind: Secret
metadata:
  name: doppler-machine-token
  namespace: default
  labels:
    app.kubernetes.io/managed-by: terraform
type: Opaque
stringData:
  dopplerToken: ${var.DOPPLER_TOKEN}
YAML
  force_new  = true
  depends_on = [k3d_cluster.maklab_cluster]
}
