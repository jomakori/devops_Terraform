# Grab the latest snapshot from PROD - needed for syncing staging w/ PROD
data "demo_app_rds_prod_snapshot" "latest_snapshot" {
  db_cluster_identifier = "${var.name}-prod-cluster"
  most_recent           = true

  depends_on = [module.demo_app_prod_db_cluster]
}

module "demo_app_staging_db_cluster" {
  source  = "cloudposse/rds-cluster/aws"
  version = "1.9.0"

  # PROD Snapshot details (for sync)
  name                = "${var.name}-staging-db-${formatdate("YYYY-MM-DD", timestamp())}" # needed to allow smooth replacement (can't be the same name)
  snapshot_identifier = data.aws_db_cluster_snapshot.latest_snapshot.id

  # Network settings
  vpc_id          = module.vpc.vpc_id
  subnets         = module.vpc.private_subnets
  security_groups = [module.shared_rds_sg.security_group_id]

  # Database engine details
  engine         = var.engine
  engine_mode    = var.scaling_mode
  engine_version = var.postgres_version
  cluster_family = var.postgres_version_class
  cluster_size   = 1 # writer only


  # Backup/Maintainance settings
  backup_window         = "02:00-04:00"         # Performed Daily
  maintenance_window    = "sun:04:10-sun:06:10" # Performed Weekly
  retention_period      = 7
  copy_tags_to_snapshot = true

  # Enhanced security
  storage_encrypted                     = true
  egress_enabled                        = false # aka no external internet access
  performance_insights_enabled          = true
  performance_insights_retention_period = 7
  enhanced_monitoring_role_enabled      = true
  rds_monitoring_interval               = 15 # Every 15 mins
  cluster_parameters                    = var.rds_enforce_ssl

  # Scaling configuration
  serverlessv2_scaling_configuration = {
    max_capacity = 12
    min_capacity = 0.5
  }

  # Deletion protection - prevent accidental removal
  deletion_protection = false

  # Tags
  tags = merge(var.rds_tags,
    {
      "env"                    = "staging",
      "Synced with Prod DB on" = formatdate("YYYY-MM-DD", timestamp())
    }
  )

  depends_on = [data.demo_app_rds_prod_snapshot.latest_snapshot]

}

/* 
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ Updates db endpoint - whenever its changed                               │
  └──────────────────────────────────────────────────────────────────────────┘
 */
resource "null_resource" "update_doppler_endpoint" {
  # Trigger the provisioner whenever the DB instance is created or updated
  triggers = {
    db_endpoint = module.demo_app_staging_db_cluster.endpoint
  }

  # Update DB endpoint via Doppler
  provisioner "local-exec" {
    command = <<EOT
        doppler secrets set POSTGRES_HOST ${module.demo_app_staging_db_cluster.endpoint} -t ${var.DOPPLER_STAGING_TOKEN} -p demo_app -c staging
        EOT
  }
}
