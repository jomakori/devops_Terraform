# Cloudflare edge resources that moved to GitOps (Crossplane, gke_GitOps).
# destroy = false drops them from Terraform state without touching Cloudflare:
# the tunnel, its remote config, the wildcard DNS record and the account IdP are
# adopted by Crossplane through their existing ids (crossplane.io/external-name).
# Tunnel token/id stay in Doppler svc_cloudflare - the cloudflared chart reads
# them from there, not from this workspace.

removed {
  from = cloudflare_zero_trust_tunnel_cloudflared.maklab
  lifecycle {
    destroy = false
  }
}

removed {
  from = cloudflare_zero_trust_tunnel_cloudflared_config.maklab
  lifecycle {
    destroy = false
  }
}

removed {
  from = cloudflare_dns_record.wildcard_maklab
  lifecycle {
    destroy = false
  }
}

removed {
  from = cloudflare_zero_trust_access_identity_provider.google_oauth
  lifecycle {
    destroy = false
  }
}

removed {
  from = doppler_secret.tunnel_token
  lifecycle {
    destroy = false
  }
}

removed {
  from = doppler_secret.tunnel_id
  lifecycle {
    destroy = false
  }
}

# Access applications that moved to Crossplane XRs (gke_GitOps#388). Their state
# entries predate the provider block being removed, so without these Terraform
# errors with "provider configuration not present" instead of planing cleanly.
removed {
  from = cloudflare_zero_trust_access_application.grafana_private
  lifecycle {
    destroy = false
  }
}

removed {
  from = cloudflare_zero_trust_access_application.openagent_private
  lifecycle {
    destroy = false
  }
}

removed {
  from = cloudflare_zero_trust_access_application.excalidash_private
  lifecycle {
    destroy = false
  }
}

removed {
  from = cloudflare_zero_trust_access_application.openkite_private
  lifecycle {
    destroy = false
  }
}

removed {
  from = cloudflare_zero_trust_access_application.design_private
  lifecycle {
    destroy = false
  }
}

removed {
  from = cloudflare_zero_trust_access_application.openkite_previews_private
  lifecycle {
    destroy = false
  }
}

# Local-only random id used for the tunnel secret; nothing exists in Cloudflare.
removed {
  from = random_id.tunnel_secret
}

# R2 backups. The bucket is one immutable object created once and imported; the
# Crossplane Cloudflare provider here only carries the zero-trust groups, so the
# bucket stays static infrastructure. Everything downstream is GitOps: bucket
# name + endpoint in the postgres-operator chart's objectStorage values, creds
# synced from Doppler svc_postgres_operator by ExternalSecret, and StackGres owns
# the backup schedule. Keeping the R2 keys in Doppler means ESO keeps working
# after the workspace forgets them.
removed {
  from = aws_s3_bucket.pg_main
  lifecycle {
    destroy = false
  }
}

removed {
  from = doppler_secret.r2_access_key_id
  lifecycle {
    destroy = false
  }
}

removed {
  from = doppler_secret.r2_secret_access_key
  lifecycle {
    destroy = false
  }
}
