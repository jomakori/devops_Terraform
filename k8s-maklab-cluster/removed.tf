removed {
  from = doppler_secret.access_audience_tag
  lifecycle {
    destroy = false
  }
}

removed {
  from = doppler_secret.cf_access_auds
  lifecycle {
    destroy = false
  }
}

removed {
  from = doppler_secret.argocd_webhook_github_secret
  lifecycle {
    destroy = false
  }
}

removed {
  from = terraform_data.k3d_ready
  lifecycle {
    destroy = false
  }
}

# Old minikube-era resource (k3d cluster is provisioned out-of-band).
# Defensive — if ever re-added to state it must not be re-created.
removed {
  from = minikube_cluster.maklab_cluster
  lifecycle {
    destroy = false
  }
}

removed {
  from = kubectl_manifest.local_path_config
  lifecycle {
    destroy = false
  }
}
