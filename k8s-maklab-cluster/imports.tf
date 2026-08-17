# Drift reconciliation — import blocks (terraform 1.5+)
# Resources that exist in the API but were never in state.

import {
  to = doppler_config.svc_tailscale
  id = "devops.svc_tailscale"
}
