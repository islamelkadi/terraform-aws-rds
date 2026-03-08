# Primary Module Example - This demonstrates the terraform-aws-rds proxy module
# Supporting infrastructure (KMS, VPC) is defined in separate files
# to keep this example focused on the module's core functionality.
#
# Basic RDS Proxy Example

module "rds_proxy" {
  source = "../"

  namespace   = var.namespace
  environment = var.environment
  name        = var.name
  region      = var.region

  engine_family = var.engine_family

  # Direct reference to vpc.tf module output
  subnet_ids = module.vpc.private_subnet_ids

  auth = [{
    auth_scheme = "SECRETS"
    description = "RDS credentials from Secrets Manager"
    iam_auth    = var.enable_iam_auth ? "REQUIRED" : "DISABLED"
    secret_arn  = var.secret_arn
  }]

  db_instance_identifier = var.db_instance_identifier

  # Direct reference to kms.tf module output
  kms_key_id = module.kms_key.key_id

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
