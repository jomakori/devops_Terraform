# k8s-maklab-cluster

Terraform-managed **k3d** Kubernetes cluster on **OrbStack** (macOS arm64), orchestrated through ArgoCD GitOps. Replaces the previous Minikube/krunkit setup.

## Architecture & Flow

Dependency chain (strict `depends_on`, left to right):

```
1-k8s.tf               ← provisions k3d cluster (1 server + 3 agents, v1.35.1, flannel CNI, containerd)
                           CoreDNS ConfigMap (forward . 8.8.8.8 force_tcp)
                           Longhorn deps installed in Docker host
                           Tailscale TLS SAN for remote API access

2-eso.tf               ← creates external-secrets namespace + stores Doppler personal token as K8s Secret
                           ClusterSecretStores in the GitOps repo reference this token with their own project+config

3-managed_services.tf  ← installs ArgoCD (helm_release.argocd) — ArgoCD can't manage itself

4-gitops.tf            ← creates "services" ArgoCD Application via App-of-Apps pattern
                           Points at gke_GitOps repo → ArgoCD auto-syncs (prune + self-heal)
                           "apps" Application is commented out — ready to activate when app workloads are ready

5-cloudflare-tunnel.tf ← Cloudflare Zero Trust tunnel + wildcard DNS + tunnel token stored to Doppler
                           Requires services (ArgoCD syncs Istio + cert-manager) already running

6-cloudflare-access.tf ← CF Access Application (Google OAuth) + Doppler AUD secret
```

Dependency: `6 ← 5 ← depends_on ← 4 ← depends_on ← 3 ← depends_on ← 2 ← depends_on ← 1`

### Structure

```
.
├── 1-k8s.tf                  # k3d cluster provisioning + CoreDNS + Longhorn deps
├── 2-eso.tf                  # ESO bootstrap — namespace + token secret
├── 3-managed_services.tf     # ArgoCD installation
├── 4-gitops.tf               # App-of-Apps manifests (services active, apps commented out)
├── 5-cloudflare-tunnel.tf    # Cloudflare tunnel + DNS + Doppler token injection
├── 6-cloudflare-access.tf    # CF Access Application + Google OAuth IdP
├── data.tf                   # Cloudflare zone data source
├── variables.tf              # cluster_config, gitops_config, tunnel_config, secrets
├── outputs.tf                # Kubeconfig (tunnel endpoint) + public_tunnel
├── versions.tf               # Provider versions + Terraform Cloud config
├── helm/
│   └── argocd-values.yaml    # ArgoCD Helm overrides (HA, PDB, HPA)
└── argocd_app-of-apps/
    ├── services.yml          # Application template for services
    └── apps.yml              # Application template for app workloads (ready but unused)
```

## Prerequisites

- **OrbStack** — Docker runtime (free for personal use, `brew install --cask orbstack`)
- **k3d CLI** — `brew install k3d`
- **Terraform** >= 1.6
- **Doppler CLI** — for `TF_VAR_` secret injection
- **Tailscale** — for remote cluster access

## Secrets

No app/service secrets pass through Terraform variables or `terraform.tfvars`. Everything flows through ESO + Doppler:

1. Terraform stores `var.DOPPLER_TOKEN` (personal token) as a K8s Secret in `external-secrets`.
2. ClusterSecretStore resources in the GitOps repo reference that token with their `project` + `config`.
3. ExternalSecrets use `dataFrom.extract` with zero rewrite rules — K8s Secret keys match Doppler key names. `refreshInterval: 1m`.
4. Pods consume via standard `secretKeyRef`.

### Infrastructure Secrets (set via `TF_VAR_` env vars — use `doppler run`)

| Variable | Source | Used By |
|----------|--------|---------|
| `DOPPLER_TOKEN` | Doppler personal token | ESO bootstrap K8s Secret |
| `CLOUDFLARE_API_TOKEN` | Cloudflare API token | Tunnel creation + DNS records |
| `CLOUDFLARE_ACCOUNT_ID` | Cloudflare account ID | Zero Trust tunnel resource |
| `ACCESS_TEAM_DOMAIN` | CF Access team domain | Istio JWT validation |
| `ACCESS_AUDIENCE_TAG` | CF Access AUD tag | Istio JWT validation |
| `GOOGLE_OAUTH_CLIENT_ID` | Google OAuth client ID | CF Access IdP |
| `GOOGLE_OAUTH_CLIENT_SECRET` | Google OAuth client secret | CF Access IdP |

## Usage

```bash
# 1. Start OrbStack (launch from Applications, or: orb start)
# 2. Deploy cluster
doppler run -p devops -- terraform apply -auto-approve

# 3. Local access (k3d auto-writes ~/.kube/config)
kubectl get nodes

# 4. Remote access (via Tailscale tunnel)
terraform output -raw kubeconfig > ~/.kube/remote-config
KUBECONFIG=~/.kube/remote-config kubectl get nodes

# 5. ArgoCD
kubectl port-forward -n argocd svc/argo-cd-argocd-server 8080:80
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# 6. GitOps services deploy automatically via ArgoCD App-of-Apps
#    Wave 0: longhorn, cert-manager, metrics-server, vpa
#    Wave 1: external-secrets (ClusterSecretStores)
#    Wave 2: istio (CRDs + control plane + gateway)
#    Wave 3: cloudflare-tunnel, kagent-substrate
#    Wave 4: external-dns, postgres-operator
#    Wave 5: kube-prometheus-stack, onedev, kagent
#    Wave 6+: apps (demoApi, notesUi)
```

## Storage

- **Longhorn** (default StorageClass) — single replica, volume expansion enabled
- **Longhorn RWX** (`longhorn-rwx`) — ReadWriteMany via NFS share-manager
- Managed via GitOps: `gke_GitOps/services/helm/longhorn/` (wave 0)

## Outputs

| Name | Description |
|------|-------------|
| `kubeconfig` | Full kubeconfig with Tailscale tunnel endpoint |
| `public_tunnel` | `https://jmak-lab.tail2354a3.ts.net:443` |
