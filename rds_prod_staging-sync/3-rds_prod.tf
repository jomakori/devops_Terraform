/* 
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ Create Production DB                                                     │
  └──────────────────────────────────────────────────────────────────────────┘
 */
module "demo_app_prod_db_cluster" {
  source  = "cloudposse/rds-cluster/aws"
  version = "1.9.0"

  name = "${var.name}-prod-cluster"

  # Network settings
  vpc_id                 = module.vpc.vpc_id
  subnets                = module.vpc.private_subnets
  vpc_security_group_ids = [module.shared_rds_sg.security_group_id]

  # Database engine details
  engine                     = var.engine
  engine_mode                = var.scaling_mode
  engine_version             = var.postgres_version
  cluster_family             = var.postgres_version_class
  cluster_size               = 1 # writer only
  autoscaling_enabled        = true
  autoscaling_target_metrics = "RDSReaderAverageCPUUtilization"

  # Database credentials
  admin_user     = var.DB_USER
  admin_password = var.DB_PASSWORD


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
  deletion_protection = true

  # Tags
  tags = merge(var.rds_tags,
    {
      "env" = "production"
    }
  )
}

/* 
  ┌──────────────────────────────────────────────────────────────────────────┐
  │ Updates db endpoint - whenever its changed                               │
  └──────────────────────────────────────────────────────────────────────────┘
 */
resource "null_resource" "update_doppler_endpoint" {
  # Triggers when DB instance is created or updated
  triggers = {
    db_change = module.demo_app_prod_db_cluster.endpoint
  }

  # Update DB cluster endpoint via Doppler
  provisioner "local-exec" {
    command = <<EOT
        doppler secrets set POSTGRES_HOST ${aws_rds_cluster.demo_app_prod_cluster.endpoint} -t ${var.DOPPLER_PROD_TOKEN} -p demo_app -c prod
        EOT
  }
}
