/*
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ OrbStack host setup                                                      │
  └──────────────────────────────────────────────────────────────────────────┘
 */

# OrbStack watchdog — restarts OrbStack when its auto-updater stops the VM to
# swap the app bundle and does not start it again (which takes the k3d cluster
# down with it). Installed into ~/Library/LaunchAgents and run every 60s.
#
# Like terraform_data.orbstack_vm_memory, this is a Mac-only side effect: CI
# runners have no launchctl user session, so the local-exec no-ops there. It
# takes effect only when applied from the Mac.
#
# The script refuses to start OrbStack unless the external data volume is
# mounted and data.img.raw is present — an unmounted volume leaves an empty
# directory at the configured data_dir, which OrbStack would initialise as a
# blank data image. See scripts/README.md for the data_dir + Full Disk Access
# prerequisites, which cannot be automated.
resource "terraform_data" "orbstack_watchdog" {
  # triggers_replace (NOT input): provisioners only run on creation, so file
  # changes must force a replacement or the installed copy silently drifts.
  triggers_replace = {
    script_sha256 = filesha256("${path.module}/scripts/orbstack-watchdog.sh")
    plist_sha256  = filesha256("${path.module}/scripts/net.maklab.orbstack-watchdog.plist")
  }

  provisioner "local-exec" {
    command = <<-EOT
      set -e
      if ! command -v launchctl >/dev/null 2>&1; then
        echo "no launchctl — skipping OrbStack watchdog install (expected on CI runners)"
        exit 0
      fi
      mkdir -p "$HOME/.local/bin" "$HOME/Library/LaunchAgents"
      install -m 755 "${path.module}/scripts/orbstack-watchdog.sh" "$HOME/.local/bin/orbstack-watchdog.sh"
      cp "${path.module}/scripts/net.maklab.orbstack-watchdog.plist" "$HOME/Library/LaunchAgents/"
      launchctl bootout "gui/$(id -u)/net.maklab.orbstack-watchdog" 2>/dev/null || true
      launchctl bootstrap "gui/$(id -u)" "$HOME/Library/LaunchAgents/net.maklab.orbstack-watchdog.plist"
      echo "OrbStack watchdog installed and loaded"
    EOT
  }
}
