# Makefile for OCI ARM VM with Tailscale integration
DOPPLER_CMD = doppler run --project devops --config ci --

.PHONY: help

help:
	@echo "Usage: make [target]"
	@echo "Targets: init plan apply destroy validate fmt clean rotate"

init:
	$(DOPPLER_CMD) terraform init

plan:
	$(DOPPLER_CMD) terraform plan

apply:
	$(DOPPLER_CMD) terraform apply -auto-approve

destroy:
	$(DOPPLER_CMD) terraform destroy -auto-approve

validate:
	$(DOPPLER_CMD) terraform validate

fmt:
	$(DOPPLER_CMD) terraform fmt -recursive

clean:
	rm -rf .terraform .terraform.lock.hcl terraform.tfstate*

rotate:
	$(DOPPLER_CMD) terraform apply -target=tailscale_key.vm_auth_key -auto-approve
	@echo "Key rotated. Reboot VM to apply."
