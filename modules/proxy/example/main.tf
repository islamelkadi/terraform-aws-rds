# Basic RDS Proxy Example

module "rds_proxy" {
  source = "../"

  namespace   = var.namespace
  environment = var.environment
  name        = var.name
  region      = var.region

  engine_family = var.engine_family
  subnet_ids    = var.subnet_ids

  auth = [{
    auth_scheme = "SECRETS"
    description = "RDS credentials from Secrets Manager"
    iam_auth    = var.enable_iam_auth ? "REQUIRED" : "DISABLED"
    secret_arn  = var.secret_arn
  }]

  db_instance_identifier = var.db_instance_identifier
  kms_key_id             = var.kms_key_arn

  connection_pool_config = {
    connection_borrow_timeout    = 120
    max_connections_percent      = 100
    max_idle_connections_percent = 50
    session_pinning_filters      = []
  }

  enable_cloudwatch_logs = var.enable_cloudwatch_logs
  log_retention_days     = var.log_retention_days

  tags = var.tags
}
