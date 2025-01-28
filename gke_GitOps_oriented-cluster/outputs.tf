output "get_credentials_command" {
  value = <<EOT
To configure kubectl to access the GKE cluster, run the following command:
gcloud container clusters get-credentials ${module.gke.name} --region ${var.region} --project ${var.project_id}
EOT
}
