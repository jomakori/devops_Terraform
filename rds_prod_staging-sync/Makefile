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
	make apply_vpc && \
	make apply_sg && \
	make apply_vpc_peering && \
	make apply_rds

## Usage: Silo target & Apply changes
apply_vpc:
	$(DOPPLER_CMD)='terraform apply -target=module.vpc --auto-approve'
apply_sg:
	$(DOPPLER_CMD)='terraform apply -target=module.shared_rds_sg --auto-approve'
apply_vpc_peering:
	$(DOPPLER_CMD)='terraform apply -target=module.vpc_peering --auto-approve' && \
	$(DOPPLER_CMD)='terraform apply -target=aws_route.rds_routes --auto-approve'
apply_rds:
	$(DOPPLER_CMD)='terraform apply -target=module.commerce_engine_prod_db_cluster --auto-approve' && \
	$(DOPPLER_CMD)='terraform apply -target=module.commerce_engine_staging_db_cluster --auto-approve'
