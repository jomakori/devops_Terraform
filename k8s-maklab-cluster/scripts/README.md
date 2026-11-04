# Host setup for the maklab k3d cluster

The cluster itself is defined in [`../k3d-cluster.yaml`](../k3d-cluster.yaml) and is
created with `k3d cluster create --config k8s-maklab-cluster/k3d-cluster.yaml`.
This directory holds the parts of the host that the cluster depends on but that
Kubernetes cannot express.

## OrbStack data lives on the external SSD

OrbStack keeps every image, container, volume and the whole k3s data directory
inside a single sparse disk image. That image is stored on the external 2 TB
APFS volume rather than the boot disk, via the (undocumented) `data_dir` key in
`~/.orbstack/vmconfig.json`:

```json
{
  "memory_mib": 53248,
  "rosetta": false,
  "ssh.expose_port": true,
  "data_dir": "/Volumes/maklab-ssd/orbstack-data"
}
```

There is no `orb config` key for this — `orb config get data_dir` reports an
unknown key. Edit the JSON while OrbStack is stopped, then start it.

Two constraints come with it:

- **The volume must be APFS.** OrbStack refuses any other filesystem.
- **OrbStack needs Full Disk Access.** macOS gates `open()` on external volumes
  behind TCC. Without the grant, `OrbStack Helper vmgr` blocks forever in
  `open()` during its `lock_data_image` startup phase — OrbStack never starts,
  with no error and no prompt, because the helper has no UI to show one. The
  grant lives in the system TCC database, so it is not visible in the per-user
  one; verify it by starting OrbStack with the external `data_dir`, not by
  querying `TCC.db`.

To roll back, remove `data_dir` from `vmconfig.json` and start OrbStack again —
it uses `~/Library/Group Containers/HUAQ24HBR6.dev.orbstack/data`.

## Watchdog

[`orbstack-watchdog.sh`](orbstack-watchdog.sh) is installed at
`~/.local/bin/orbstack-watchdog.sh` and run every 60 s by
[`net.maklab.orbstack-watchdog.plist`](net.maklab.orbstack-watchdog.plist)
installed at `~/Library/LaunchAgents/`. It restarts OrbStack after its
auto-updater stops the VM without restarting it.

Installation is owned by `terraform_data.orbstack_watchdog` in
[`../8-host.tf`](../8-host.tf), which re-installs and reloads the agent whenever
either file changes. On CI runners it no-ops (no `launchctl`), so the files only
take effect when Terraform is applied from the Mac.

It refuses to start OrbStack unless the data volume is mounted and
`data.img.raw` is present and plausibly sized. An unmounted volume leaves an
empty directory at the configured path, and starting OrbStack against it is the
one way to end up on a blank data image — OrbStack's own "disconnected drive"
protection keys on a missing drive, not on an empty directory.

Pause it around any manual OrbStack stop, or it will restart the VM mid-copy:

```sh
touch ~/.orbstack-watchdog-pause     # pause
rm ~/.orbstack-watchdog-pause        # resume
```

Manual install, if Terraform cannot be applied from the Mac:

```sh
install -m 755 k8s-maklab-cluster/scripts/orbstack-watchdog.sh ~/.local/bin/orbstack-watchdog.sh
cp k8s-maklab-cluster/scripts/net.maklab.orbstack-watchdog.plist ~/Library/LaunchAgents/
launchctl bootout gui/$(id -u)/net.maklab.orbstack-watchdog 2>/dev/null
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/net.maklab.orbstack-watchdog.plist
```

## Verifying the data location

```sh
# the image OrbStack actually has open
lsof "/Volumes/maklab-ssd/orbstack-data/data.img.raw" | head

# the internal image must be frozen while the cluster runs
stat -f '%Sm' ~/Library/Group\ Containers/HUAQ24HBR6.dev.orbstack/data/data.img.raw

# cluster health
kubectl get nodes
```
