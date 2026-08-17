# Drift reconciliation — state moves (terraform 1.5+)
# CF Access apps were refactored from a map (private["..."]) to standalone
# resources. Same live apps — rename in state so no destroy/create occurs.

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
