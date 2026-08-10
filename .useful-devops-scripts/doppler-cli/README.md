# Doppler CLI Installer

GitOps-managed installer for the [Doppler CLI](https://docs.doppler.com/docs/install-cli),
so secrets can be managed from the terminal instead of the REST API:

```bash
# Set / update a secret
doppler secrets set MY_KEY=my_value --project devops --config svc

# Set multiple / from env file
doppler secrets set --project devops --config svc < .env

# Read a secret
doppler secrets get MY_KEY --project devops --config svc
```

## Install

```bash
# Latest version → ~/.local/bin
./install-doppler-cli.sh

# Pinned version → custom path
./install-doppler-cli.sh 3.71.2 /usr/local/bin
```

Requires `curl` + `tar`. Signature verification happens automatically when
`gpgv` (gnupg) is installed; otherwise installs with a warning.

## Auth

```bash
# Interactive (browser or device flow)
doppler login

# Or token-based (CI / automation)
export DOPPLER_TOKEN="dp.ct.xxxx"
```

## Why

The maklab cluster (k8s-maklab-cluster workspace) uses Doppler for all
secrets via ExternalSecrets. Having the CLI locally makes one-off secret
writes (e.g. Tailscale OAuth credentials, Cloudflare AUDs) a one-liner
instead of a REST call. Mirrors the repo's pipeline-image convention:
[`.circleci/config.yml`](../.circleci/config.yml) keeps the CLI version
current in CI; this script keeps it current locally.
