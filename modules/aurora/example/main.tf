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

  subnet_ids             = var.subnet_ids
  vpc_security_group_ids = var.vpc_security_group_ids

  kms_key_arn = var.kms_key_arn

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
