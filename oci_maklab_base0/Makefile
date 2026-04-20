# Makefile for OCI ARM VM with Tailscale integration
DOPPLER_CMD = doppler run --project devops --config ci --

.PHONY: help init plan apply apply-retry destroy validate fmt clean rotate

help:
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@echo "  init         - Initialize Terraform"
	@echo "  plan         - Show execution plan"
	@echo "  apply        - Apply changes (single attempt)"
	@echo "  apply-retry  - Apply with capacity retry (for ARM instances)"
	@echo "  destroy      - Destroy all resources"
	@echo "  validate     - Validate configuration"
	@echo "  fmt          - Format Terraform files"
	@echo "  clean        - Remove local Terraform files"
	@echo "  rotate       - Rotate Tailscale auth key"
	@echo ""
	@echo "Capacity Tips:"
	@echo "  - ARM instances often have capacity issues"
	@echo "  - Use 'make apply-retry' for automatic retries"
	@echo "  - Try off-peak hours (early morning UTC)"
	@echo "  - Consider smaller instance: vm_cpu=1 vm_memory=6"

init:
	$(DOPPLER_CMD) terraform init

plan:
	$(DOPPLER_CMD) terraform plan

apply:
	$(DOPPLER_CMD) terraform apply -auto-approve

apply-retry:
	@chmod +x scripts/retry_capacity.sh
	@cd $(CURDIR) && ./scripts/retry_capacity.sh 30 60

apply-small:
	$(DOPPLER_CMD) terraform apply -auto-approve -var="vm_cpu=1" -var="vm_memory=6"

destroy:
	$(DOPPLER_CMD) terraform destroy -auto-approve

validate:
	$(DOPPLER_CMD) terraform validate

fmt:
	$(DOPPLER_CMD) terraform fmt -recursive

clean:
	rm -rf .terraform .terraform.lock.hcl terraform.tfstate*

rotate:
	$(DOPPLER_CMD) terraform apply -target=tailscale_tailnet_key.vm_auth_key -auto-approve
	@echo "Key rotated. Reboot VM to apply."
