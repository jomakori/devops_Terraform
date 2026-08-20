# Extract k3s version from variables.tf default
K3S_VERSION := $(shell grep 'kubernetes_version' variables.tf | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+-k3s[0-9]+')
IMAGE_REPO  := ghcr.io/jomakori/k3s-iscsi
IMAGE_TAG   := $(IMAGE_REPO):$(K3S_VERSION)
CLUSTER     := $(shell grep 'name' variables.tf | grep '"' | head -1 | tr -d '"')
DOPPLER     := doppler run -p devops -c ci --
TF          := $(DOPPLER) terraform

.PHONY: k3s-image k3s-image-build k3s-image-push \
        init plan plan-cluster plan-eso plan-argocd plan-gitops plan-tunnel plan-access \
        apply apply-cluster apply-eso apply-argocd apply-gitops apply-tunnel apply-access \
        destroy destroy-access destroy-tunnel destroy-gitops destroy-argocd destroy-eso destroy-cluster \
        output fmt clean

.DEFAULT_GOAL := plan

# ═══ Setup ═══

init:
	$(TF) init -upgrade

fmt:
	$(TF) fmt -recursive

output:
	$(TF) output

# ═══ K3S Image ═══

k3s-image: k3s-image-build k3s-image-push

k3s-image-build:
	@echo "Building $(IMAGE_TAG)..."
	docker buildx build --platform linux/arm64 \
		-t $(IMAGE_TAG) -t $(IMAGE_REPO):latest --load .
	@echo "Built: $(IMAGE_TAG)"

k3s-image-push:
	@echo "Pushing $(IMAGE_TAG)..."
	docker push $(IMAGE_TAG) && docker push $(IMAGE_REPO):latest
	@echo "Pushed: $(IMAGE_TAG)"

# ═══ Plan — preview each step ═══

plan: plan-cluster plan-eso plan-argocd plan-gitops plan-tunnel plan-access
	@echo "✓ Full plan complete"

plan-cluster:
	$(TF) plan -target=k3d_cluster.maklab_cluster -target=data.external.k3d_dns -target=kubectl_manifest.coredns_config

plan-eso:
	$(TF) plan -target=kubectl_manifest.doppler_machine_token_secret

plan-argocd:
	$(TF) plan -target=helm_release.argocd

plan-gitops:
	$(TF) plan -target=kubectl_manifest.services

plan-tunnel:
	$(TF) plan \
		-target=random_id.tunnel_secret \
		-target=cloudflare_zero_trust_tunnel_cloudflared.maklab \
		-target=cloudflare_zero_trust_tunnel_cloudflared_config.maklab \
		-target=data.cloudflare_zero_trust_tunnel_cloudflared_token.maklab \
		-target=doppler_secret.tunnel_token \
		-target=doppler_secret.tunnel_id \
		-target=cloudflare_dns_record.wildcard_maklab

plan-access:
	$(TF) plan \
		-target=cloudflare_zero_trust_access_identity_provider.google_oauth \
		-target=cloudflare_zero_trust_access_application.maklab_private \
		-target=doppler_secret.cf_access_aud

# ═══ Apply — dependency order ═══

apply: apply-cluster apply-eso apply-argocd apply-gitops apply-tunnel apply-access
	@echo "✓ All resources applied"

apply-cluster:
	$(TF) apply -auto-approve \
		-target=k3d_cluster.maklab_cluster \
		-target=data.external.k3d_dns \
		-target=kubectl_manifest.coredns_config

apply-eso:
	$(TF) apply -auto-approve \
		-target=kubectl_manifest.doppler_machine_token_secret

apply-argocd:
	$(TF) apply -auto-approve \
		-target=helm_release.argocd

apply-gitops:
	$(TF) apply -auto-approve \
		-target=kubectl_manifest.services

apply-tunnel:
	$(TF) apply -auto-approve \
		-target=random_id.tunnel_secret \
		-target=cloudflare_zero_trust_tunnel_cloudflared.maklab \
		-target=cloudflare_zero_trust_tunnel_cloudflared_config.maklab \
		-target=data.cloudflare_zero_trust_tunnel_cloudflared_token.maklab \
		-target=doppler_secret.tunnel_token \
		-target=doppler_secret.tunnel_id \
		-target=cloudflare_dns_record.wildcard_maklab

apply-access:
	$(TF) apply -auto-approve \
		-target=cloudflare_zero_trust_access_identity_provider.google_oauth \
		-target=cloudflare_zero_trust_access_application.maklab_private \
		-target=doppler_secret.cf_access_aud

# ═══ Destroy — reverse order ═══

destroy: destroy-access destroy-tunnel destroy-gitops destroy-argocd destroy-eso destroy-cluster
	@echo "✓ All resources destroyed"

destroy-access:
	$(TF) destroy -auto-approve \
		-target=doppler_secret.cf_access_aud \
		-target=cloudflare_zero_trust_access_application.maklab_private \
		-target=cloudflare_zero_trust_access_identity_provider.google_oauth

destroy-tunnel:
	$(TF) destroy -auto-approve \
		-target=cloudflare_dns_record.wildcard_maklab \
		-target=doppler_secret.tunnel_id \
		-target=doppler_secret.tunnel_token \
		-target=data.cloudflare_zero_trust_tunnel_cloudflared_token.maklab \
		-target=cloudflare_zero_trust_tunnel_cloudflared_config.maklab \
		-target=cloudflare_zero_trust_tunnel_cloudflared.maklab \
		-target=random_id.tunnel_secret

destroy-gitops:
	$(TF) destroy -auto-approve \
		-target=kubectl_manifest.services

destroy-argocd:
	$(TF) destroy -auto-approve \
		-target=helm_release.argocd

destroy-eso:
	$(TF) destroy -auto-approve \
		-target=kubectl_manifest.doppler_machine_token_secret

destroy-cluster:
	$(TF) destroy -auto-approve \
		-target=kubectl_manifest.coredns_config \
		-target=data.external.k3d_dns \
		-target=k3d_cluster.maklab_cluster

# ═══ Full teardown ═══

clean:
	k3d cluster delete $(CLUSTER)
