# Drift reconciliation — drop legacy state entries WITHOUT destroying the
# real objects. The Doppler secrets are still consumed at runtime (appset
# ACCESS_AUDIENCE_TAG var, ESO, ArgoCD webhook) so they must stay live.
# k3d_ready is a dead k3d-era marker with no real object.

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
