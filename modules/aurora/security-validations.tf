# Security Controls Validations
# Enforces security standards based on metadata module security controls
# Supports selective overrides with documented justification

locals {
  # Use security controls if provided, otherwise use permissive defaults
  security_controls = var.security_controls != null ? var.security_controls : {
    encryption = {
      require_kms_customer_managed  = false
      require_encryption_at_rest    = false
      require_encryption_in_transit = false
      enable_kms_key_rotation       = false
    }
    logging = {
      require_cloudwatch_logs = false
      min_log_retention_days  = 1
      require_access_logging  = false
      require_flow_logs       = false
    }
    monitoring = {
      enable_xray_tracing         = false
      enable_enhanced_monitoring  = false
      enable_performance_insights = false
      require_cloudtrail          = false
    }
    network = {
      require_private_subnets = false
      require_vpc_endpoints   = false
      block_public_ingress    = false
      require_imdsv2          = false
    }
    compliance = {
      enable_point_in_time_recovery = false
      require_reserved_concurrency  = false
      enable_deletion_protection    = false
    }
    data_protection = {
      require_versioning  = false
      require_mfa_delete  = false
      require_backup      = false
      require_lifecycle   = false
      block_public_access = false
      require_replication = false
    }
    high_availability = {
      require_multi_az = false
    }
  }

  # Apply overrides to security controls
  # Controls are enforced UNLESS explicitly overridden with justification
  kms_encryption_required       = local.security_controls.encryption.require_kms_customer_managed && !var.security_control_overrides.disable_kms_requirement
  backup_required               = local.security_controls.data_protection.require_backup && !var.security_control_overrides.disable_backup_requirement
  enhanced_monitoring_required  = local.security_controls.monitoring.enable_enhanced_monitoring && !var.security_control_overrides.disable_enhanced_monitoring
  performance_insights_required = local.security_controls.monitoring.enable_performance_insights && !var.security_control_overrides.disable_performance_insights
  deletion_protection_required  = local.security_controls.compliance.enable_deletion_protection && !var.security_control_overrides.disable_deletion_protection
  multi_az_required             = local.security_controls.high_availability.require_multi_az && !var.security_control_overrides.disable_multi_az_requirement

  # Validation results
  kms_validation_passed                  = !local.kms_encryption_required || var.kms_key_arn != null
  backup_validation_passed               = !local.backup_required || var.backup_retention_period > 0
  enhanced_monitoring_validation_passed  = !local.enhanced_monitoring_required || (var.enabled_cloudwatch_logs_exports != null && length(var.enabled_cloudwatch_logs_exports) > 0)
  performance_insights_validation_passed = !local.performance_insights_required || var.enable_performance_insights
  deletion_protection_validation_passed  = !local.deletion_protection_required || var.deletion_protection
  multi_az_validation_passed             = !local.multi_az_required || var.instance_count > 1

  # Audit trail for overrides
  has_overrides = (
    var.security_control_overrides.disable_kms_requirement ||
    var.security_control_overrides.disable_backup_requirement ||
    var.security_control_overrides.disable_enhanced_monitoring ||
    var.security_control_overrides.disable_performance_insights ||
    var.security_control_overrides.disable_deletion_protection ||
    var.security_control_overrides.disable_multi_az_requirement
  )

  justification_provided = var.security_control_overrides.justification != ""
  override_audit_passed  = !local.has_overrides || local.justification_provided
}

# Security Controls Check Block
check "security_controls_compliance" {
  assert {
    condition     = local.kms_validation_passed
    error_message = "Security control violation: KMS customer-managed key is required but kms_key_arn is not provided. Set security_control_overrides.disable_kms_requirement=true with justification if this is intentional."
  }

  assert {
    condition     = local.backup_validation_passed
    error_message = "Security control violation: Automated backups are required but backup_retention_period is 0. Set security_control_overrides.disable_backup_requirement=true with justification if this is a dev/test database."
  }

  assert {
    condition     = local.enhanced_monitoring_validation_passed
    error_message = "Security control violation: Enhanced monitoring (CloudWatch Logs) is required but enabled_cloudwatch_logs_exports is not configured. Set security_control_overrides.disable_enhanced_monitoring=true with justification if this is intentional."
  }

  assert {
    condition     = local.performance_insights_validation_passed
    error_message = "Security control violation: Performance Insights is required but enable_performance_insights is false. Set security_control_overrides.disable_performance_insights=true with justification if this is a dev/test database."
  }

  assert {
    condition     = local.deletion_protection_validation_passed
    error_message = "Security control violation: Deletion protection is required but deletion_protection is false. Set security_control_overrides.disable_deletion_protection=true with justification if this is intentional."
  }

  assert {
    condition     = local.multi_az_validation_passed
    error_message = "Security control violation: Multi-AZ deployment is required but instance_count is 1. Set instance_count > 1 or set security_control_overrides.disable_multi_az_requirement=true with justification if this is a dev/test database."
  }

  assert {
    condition     = local.override_audit_passed
    error_message = "Security control overrides detected but no justification provided. Please document the business reason in security_control_overrides.justification for audit compliance."
  }
}
