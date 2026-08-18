moved {
  from = cloudflare_zero_trust_access_application.private["excalidash"]
  to   = cloudflare_zero_trust_access_application.excalidash_private
}

moved {
  from = cloudflare_zero_trust_access_application.private["grafana"]
  to   = cloudflare_zero_trust_access_application.grafana_private
}

moved {
  from = cloudflare_zero_trust_access_application.private["openagent"]
  to   = cloudflare_zero_trust_access_application.openagent_private
}
