# Variables
DOPPLER_CMD := doppler run --command

# Commands
#--------------------------------------------------------------------------------------------#
#------------------------------ Terraform Auto-Apply Commands -------------------------------#
#--------------------------------------------------------------------------------------------#
apply:
	$(DOPPLER_CMD)='terraform apply --auto-approve'

## Usage: If mass-change impacting multiple modules, its better to run this individually in order to avoid breakage/errors
apply_mass:
	$(DOPPLER_CMD)='terraform apply -target=module.eks --auto-approve' && \
	$(DOPPLER_CMD)='terraform apply -target=module.cluster_sg_rules --auto-approve' && \
	$(DOPPLER_CMD)='terraform apply -target=module.eks_node_group --auto-approve' && \
	$(DOPPLER_CMD)='terraform apply -target=module.eks_blueprints_addons --auto-approve' && \
	$(DOPPLER_CMD)='terraform apply -target=helm_release.argocd --auto-approve' && \
	$(DOPPLER_CMD)='terraform apply -target=kubernetes_secret.private_repo_access --auto-approve' && \
	$(DOPPLER_CMD)='terraform apply -target=kubectl_manifest.services --auto-approve' && \
	$(DOPPLER_CMD)='terraform apply -target=kubectl_manifest.service_provisioners --auto-approve' && \
	$(DOPPLER_CMD)='terraform apply -target=kubectl_manifest.apps --auto-approve' && \
	$(DOPPLER_CMD)='terraform apply --auto-approve'

## Usage: Silo target & Apply changes
apply_vpc:
	$(DOPPLER_CMD)='terraform apply -target=module.vpc --auto-approve'
apply_vpc_peering:
	$(DOPPLER_CMD)='terraform apply -target=module.vpc_peering --auto-approve'
apply_eks:
	$(DOPPLER_CMD)='terraform apply -target=module.eks --auto-approve' && \
	$(DOPPLER_CMD)='terraform apply -target=module.cluster_sg_rules --auto-approve' && \
	$(DOPPLER_CMD)='terraform apply -target=module.eks_node_group --auto-approve'
apply_eks_addons:
	$(DOPPLER_CMD)='terraform apply -target=module.eks_blueprints_addons --auto-approve'
apply_argocd:
	$(DOPPLER_CMD)='terraform apply -target=helm_release.argocd --auto-approve'
apply_services:
	$(DOPPLER_CMD)='terraform apply -target=kubectl_manifest.service_provisioners --auto-approve' && \
	$(DOPPLER_CMD)='terraform apply -target=kubectl_manifest.service_provisioners --auto-approve'
apply_apps:
	$(DOPPLER_CMD)='terraform apply -target=kubectl_manifest.apps --auto-approve'

#--------------------------------------------------------------------------------------------#
#----------------------------- Terraform Auto-Destroy Commands ------------------------------#
#--------------------------------------------------------------------------------------------#
## Usage: Destroy gracefully
destroy_mass:
	$(DOPPLER_CMD)='terraform destroy -target=kubectl_manifest.apps --auto-approve' && \
	$(DOPPLER_CMD)='terraform destroy -target=kubectl_manifest.service_provisioners --auto-approve' && \
	$(DOPPLER_CMD)='terraform destroy -target=kubectl_manifest.services --auto-approve' && \
	$(DOPPLER_CMD)='terraform destroy -target=kubernetes_secret.private_repo_access --auto-approve' && \
	$(DOPPLER_CMD)='terraform destroy -target=helm_release.argocd --auto-approve' && \
	$(DOPPLER_CMD)='terraform destroy -target=module.eks_blueprints_addons --auto-approve' && \
	$(DOPPLER_CMD)='terraform destroy -target=module.eks_node_group --auto-approve' && \
	$(DOPPLER_CMD)='terraform destroy -target=module.eks --auto-approve' && \
	$(DOPPLER_CMD)='terraform destroy -target=module.vpc_peering --auto-approve' && \
	$(DOPPLER_CMD)='terraform destroy -target=module.vpc --auto-approve' && \
	$(DOPPLER_CMD)='terraform destroy --auto-approve'

## Usage: Silo target & Destroy changes
destroy_apps:
	$(DOPPLER_CMD)='terraform destroy -target=kubectl_manifest.apps --auto-approve'
destroy_services:
	$(DOPPLER_CMD)='terraform destroy -target=kubectl_manifest.service_provisioners --auto-approve' && \
	$(DOPPLER_CMD)='terraform destroy -target=kubectl_manifest.services --auto-approve'
destroy_argocd:
	$(DOPPLER_CMD)='terraform destroy -target=helm_release.argocd --auto-approve'
destroy_eks_addons:
	$(DOPPLER_CMD)='terraform destroy -target=module.eks_blueprints_addons --auto-approve'
destroy_eks:
	$(DOPPLER_CMD)='terraform destroy -target=module.eks_node_group --auto-approve' && \
	$(DOPPLER_CMD)='terraform destroy -target=module.eks --auto-approve'
destroy_vpc_peering:
	$(DOPPLER_CMD)='terraform destroy -target=module.vpc_peering --auto-approve'
destroy_vpc:
	$(DOPPLER_CMD)='terraform destroy -target=module.vpc --auto-approve' && \
	$(DOPPLER_CMD)='terraform destroy --auto-approve'
