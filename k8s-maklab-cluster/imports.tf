# Drift reconciliation — import blocks (terraform 1.5+)
# Resources that exist in the API but were never in state.
# doppler_config import IDs are {project}.{environment}.{name}.

import {
  to = doppler_config.svc_tailscale
  id = "devops.svc.svc_tailscale"
}
