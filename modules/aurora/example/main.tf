# Primary Module Example - This demonstrates the terraform-aws-rds Aurora module
# Supporting infrastructure (KMS, VPC) is defined in separate files
# to keep this example focused on the module's core functionality.
#
# Basic Aurora PostgreSQL Example

module "aurora" {
  source = "../"

  namespace   = var.namespace
  environment = var.environment
  name        = var.name
  region      = var.region

  database_name   = var.database_name
  master_username = var.master_username
  master_password = var.master_password

  # Direct reference to vpc.tf module outputs
  subnet_ids             = module.vpc.private_subnet_ids
  vpc_security_group_ids = [module.security_group.security_group_id]

  # Direct reference to kms.tf module output
  kms_key_arn = module.kms_key.key_arn

  min_capacity = var.min_capacity
  max_capacity = var.max_capacity

  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = var.preferred_backup_window
  preferred_maintenance_window = var.preferred_maintenance_window

  instance_count = var.instance_count

  enable_performance_insights     = var.enable_performance_insights
  monitoring_interval             = var.monitoring_interval
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  deletion_protection = var.deletion_protection
  skip_final_snapshot = var.skip_final_snapshot
  apply_immediately   = var.apply_immediately

  tags = var.tags
}
