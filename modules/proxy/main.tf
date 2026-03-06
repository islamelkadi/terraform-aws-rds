# RDS Proxy Module
# Provides connection pooling and improved availability for RDS databases

# Local variables
locals {
  # Construct proxy name using naming convention
  name_parts = concat(
    [var.namespace],
    [var.environment],
    [var.name],
    var.attributes
  )
  proxy_name = join(var.delimiter, local.name_parts)

  # Merge security controls with defaults
  security_controls = var.security_controls != null ? var.security_controls : {
    encryption = {
      require_kms_customer_managed  = true
      require_encryption_at_rest    = true
      require_encryption_in_transit = true
      enable_kms_key_rotation       = true
    }
    logging = {
      require_cloudwatch_logs = true
      min_log_retention_days  = 365
      require_access_logging  = false
      require_flow_logs       = false
    }
    monitoring = {
      enable_xray_tracing         = false
      enable_enhanced_monitoring  = true
      enable_performance_insights = false
      require_cloudtrail          = false
    }
    network = {
      require_private_subnets = true
      require_vpc_endpoints   = false
      block_public_ingress    = true
      require_imdsv2          = false
    }
    compliance = {
      enable_point_in_time_recovery = false
      require_reserved_concurrency  = false
      enable_deletion_protection    = false
    }
  }

  # Security control validations
  kms_required            = local.security_controls.encryption.require_kms_customer_managed && !var.security_control_overrides.disable_kms_requirement
  logging_required        = local.security_controls.logging.require_cloudwatch_logs && !var.security_control_overrides.disable_logging_requirement
  private_subnet_required = local.security_controls.network.require_private_subnets && !var.security_control_overrides.disable_private_subnet_requirement

  # Validation checks
  kms_validation_passed            = !local.kms_required || (var.auth != null && length(var.auth) > 0 && alltrue([for a in var.auth : a.iam_auth == "REQUIRED" || a.secret_arn != null]))
  logging_validation_passed        = !local.logging_required || var.enable_cloudwatch_logs
  private_subnet_validation_passed = !local.private_subnet_required || (var.subnet_ids != null && length(var.subnet_ids) >= 2)

  # Audit trail validation
  has_overrides = (
    var.security_control_overrides.disable_kms_requirement ||
    var.security_control_overrides.disable_logging_requirement ||
    var.security_control_overrides.disable_private_subnet_requirement
  )
  justification_provided = var.security_control_overrides.justification != ""
  override_audit_passed  = !local.has_overrides || local.justification_provided

  # Tags
  tags = merge(
    var.tags,
    {
      Namespace   = var.namespace
      Environment = var.environment
      Name        = var.name
      Module      = "terraform-aws-rds/proxy"
      Description = "RDS Proxy for connection pooling and high availability"
    }
  )
}

# Security control compliance checks
check "security_controls_compliance" {
  assert {
    condition     = local.kms_validation_passed
    error_message = "Security control violation: KMS encryption required for RDS Proxy authentication. Ensure all auth configurations use IAM or Secrets Manager with KMS. Set security_control_overrides.disable_kms_requirement=true with justification if this is intentional."
  }

  assert {
    condition     = local.logging_validation_passed
    error_message = "Security control violation: CloudWatch Logs required for RDS Proxy. Set enable_cloudwatch_logs=true or set security_control_overrides.disable_logging_requirement=true with justification."
  }

  assert {
    condition     = local.private_subnet_validation_passed
    error_message = "Security control violation: RDS Proxy must be deployed in private subnets (minimum 2 for HA). Provide subnet_ids or set security_control_overrides.disable_private_subnet_requirement=true with justification."
  }

  assert {
    condition     = local.override_audit_passed
    error_message = "Security control overrides detected but no justification provided. Please document the business reason in security_control_overrides.justification."
  }
}

# IAM role for RDS Proxy
resource "aws_iam_role" "proxy" {
  name               = "${local.proxy_name}-role"
  assume_role_policy = data.aws_iam_policy_document.proxy_assume_role.json

  tags = local.tags
}

data "aws_iam_policy_document" "proxy_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["rds.amazonaws.com"]
    }
  }
}

# IAM policy for Secrets Manager access
resource "aws_iam_role_policy" "proxy_secrets" {
  count = length([for a in var.auth : a if a.secret_arn != null]) > 0 ? 1 : 0

  name   = "${local.proxy_name}-secrets"
  role   = aws_iam_role.proxy.id
  policy = data.aws_iam_policy_document.proxy_secrets[0].json
}

data "aws_iam_policy_document" "proxy_secrets" {
  count = length([for a in var.auth : a if a.secret_arn != null]) > 0 ? 1 : 0

  statement {
    actions = [
      "secretsmanager:GetSecretValue"
    ]

    resources = [for a in var.auth : a.secret_arn if a.secret_arn != null]
  }

  # KMS permissions for encrypted secrets
  dynamic "statement" {
    for_each = var.kms_key_id != null ? [1] : []

    content {
      actions = [
        "kms:Decrypt",
        "kms:DescribeKey"
      ]

      resources = [var.kms_key_id]
    }
  }
}

# RDS Proxy
resource "aws_db_proxy" "this" {
  name                = local.proxy_name
  engine_family       = var.engine_family
  role_arn            = aws_iam_role.proxy.arn
  vpc_subnet_ids      = var.subnet_ids
  require_tls         = var.require_tls
  idle_client_timeout = var.idle_client_timeout
  debug_logging       = var.debug_logging

  # Auth blocks (dynamic based on var.auth list)
  dynamic "auth" {
    for_each = var.auth
    content {
      auth_scheme = auth.value.auth_scheme
      description = auth.value.description
      iam_auth    = auth.value.iam_auth
      secret_arn  = auth.value.secret_arn
      username    = auth.value.username
    }
  }

  tags = local.tags
}

# RDS Proxy target group
resource "aws_db_proxy_default_target_group" "this" {
  db_proxy_name = aws_db_proxy.this.name

  connection_pool_config {
    connection_borrow_timeout    = var.connection_pool_config.connection_borrow_timeout
    init_query                   = var.connection_pool_config.init_query
    max_connections_percent      = var.connection_pool_config.max_connections_percent
    max_idle_connections_percent = var.connection_pool_config.max_idle_connections_percent
    session_pinning_filters      = var.connection_pool_config.session_pinning_filters
  }
}

# RDS Proxy target (database)
resource "aws_db_proxy_target" "this" {
  count = var.db_instance_identifier != null ? 1 : 0

  db_proxy_name          = aws_db_proxy.this.name
  target_group_name      = aws_db_proxy_default_target_group.this.name
  db_instance_identifier = var.db_instance_identifier
}

# RDS Proxy target (cluster)
resource "aws_db_proxy_target" "cluster" {
  count = var.db_cluster_identifier != null ? 1 : 0

  db_proxy_name         = aws_db_proxy.this.name
  target_group_name     = aws_db_proxy_default_target_group.this.name
  db_cluster_identifier = var.db_cluster_identifier
}

# CloudWatch Log Group for RDS Proxy
resource "aws_cloudwatch_log_group" "proxy" {
  count = var.enable_cloudwatch_logs ? 1 : 0

  name              = "/aws/rds/proxy/${local.proxy_name}"
  retention_in_days = var.log_retention_days
  kms_key_id        = var.kms_key_id

  tags = local.tags
}
