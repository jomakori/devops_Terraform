#!/bin/bash
# orbstack-watchdog — restart OrbStack if it is stopped.
#
# Run every 60s by ~/Library/LaunchAgents/net.maklab.orbstack-watchdog.plist.
# OrbStack's auto-updater stops the VM to swap the app bundle and does not
# always start it again, which takes down the k3d cluster (litellm, tunnel).
#
# Pause:  touch ~/.orbstack-watchdog-pause   (e.g. to stop OrbStack on purpose)
# Resume: rm ~/.orbstack-watchdog-pause
#
# OrbStack's Docker/k3s data lives on an external APFS volume, configured via
# `data_dir` in ~/.orbstack/vmconfig.json (see host/README.md). Starting
# OrbStack while that volume is absent is the one way to end up on a blank
# data image, so the mount and the image are hard preconditions here.

set -u
export PATH="/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"

LOG="$HOME/Library/Logs/orbstack-watchdog.log"
APP="/Applications/OrbStack.app"
DATA_DIR="/Volumes/maklab-ssd/orbstack-data"
DATA_IMG="$DATA_DIR/data.img.raw"
MOUNT_POINT="${DATA_DIR%/*}"

log() { echo "$(date '+%Y-%m-%d %H:%M:%S') $*" >> "$LOG"; }

[ -e "$HOME/.orbstack-watchdog-pause" ] && exit 0

# Hard precondition: the external data volume must be mounted and hold the
# image. An unmounted volume leaves an empty directory at DATA_DIR, which
# OrbStack would initialize as a fresh (blank) data image.
if ! mount | grep -q " on ${MOUNT_POINT} "; then
  log "skip: ${MOUNT_POINT} not mounted"
  exit 0
fi
if [ ! -f "$DATA_IMG" ]; then
  log "skip: ${DATA_IMG} missing"
  exit 0
fi
size=$(stat -f %z "$DATA_IMG" 2>/dev/null || echo 0)
if [ "$size" -lt 100000000000 ]; then
  log "skip: ${DATA_IMG} suspiciously small (${size} bytes)"
  exit 0
fi

command -v orb >/dev/null || { log "orb not found"; exit 0; }

status=$(orb status 2>/dev/null)
[ "$status" = "Running" ] && exit 0
# Mid-start or mid-stop: let it settle.
[ "$status" = "Starting" ] || [ "$status" = "Stopping" ] && exit 0

# Don't race an in-flight update: skip while Sparkle is running or the app
# bundle was replaced in the last 2 minutes.
if pgrep -qf "OrbStack.*(Autoupdate|Sparkle|Installer)"; then
  log "status=$status; update in progress, waiting"
  exit 0
fi
age=$(( $(date +%s) - $(stat -f %m "$APP" 2>/dev/null || echo 0) ))
if [ "$age" -lt 120 ]; then
  log "status=$status; app bundle changed ${age}s ago, waiting"
  exit 0
fi

log "status=${status:-unknown}; starting OrbStack"
if out=$(orb start 2>&1); then
  log "started: $(orb status 2>/dev/null)"
else
  log "orb start failed: $out"
fi
