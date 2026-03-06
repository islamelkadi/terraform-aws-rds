# RDS Proxy Module Variables

# Metadata variables for consistent naming
variable "namespace" {
  description = "Namespace (organization/team name)"
  type        = string
}

variable "environment" {
  description = "Environment name (dev, staging, prod)"
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod"
  }
}

variable "name" {
  description = "Name of the RDS Proxy"
  type        = string
}

variable "attributes" {
  description = "Additional attributes for naming"
  type        = list(string)
  default     = []
}

variable "delimiter" {
  description = "Delimiter to use between name components"
  type        = string
  default     = "-"
}

variable "tags" {
  description = "Additional tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "region" {
  description = "AWS region where resources will be created"
  type        = string
}

# RDS Proxy Configuration
variable "engine_family" {
  description = "Database engine family (MYSQL, POSTGRESQL, SQLSERVER)"
  type        = string

  validation {
    condition     = contains(["MYSQL", "POSTGRESQL", "SQLSERVER"], var.engine_family)
    error_message = "Engine family must be MYSQL, POSTGRESQL, or SQLSERVER"
  }
}

variable "auth" {
  description = "Authentication configuration for RDS Proxy"
  type = list(object({
    auth_scheme = optional(string, "SECRETS")
    description = optional(string)
    iam_auth    = optional(string, "DISABLED")
    secret_arn  = optional(string)
    username    = optional(string)
  }))

  validation {
    condition = alltrue([
      for a in var.auth : contains(["SECRETS"], a.auth_scheme)
    ])
    error_message = "Auth scheme must be SECRETS"
  }

  validation {
    condition = alltrue([
      for a in var.auth : contains(["DISABLED", "REQUIRED"], a.iam_auth)
    ])
    error_message = "IAM auth must be DISABLED or REQUIRED"
  }
}

variable "subnet_ids" {
  description = "List of VPC subnet IDs for RDS Proxy (minimum 2 for HA)"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least 2 subnet IDs required for high availability"
  }
}

variable "require_tls" {
  description = "Require TLS for connections to RDS Proxy"
  type        = bool
  default     = true
}

variable "idle_client_timeout" {
  description = "Number of seconds a connection can be idle before being closed (300-28800)"
  type        = number
  default     = 1800 # 30 minutes

  validation {
    condition     = var.idle_client_timeout >= 300 && var.idle_client_timeout <= 28800
    error_message = "Idle client timeout must be between 300 and 28800 seconds"
  }
}

variable "debug_logging" {
  description = "Enable detailed logging for debugging"
  type        = bool
  default     = false
}

# Connection Pool Configuration
variable "connection_pool_config" {
  description = "Connection pool configuration for RDS Proxy"
  type = object({
    connection_borrow_timeout    = optional(number, 120)
    init_query                   = optional(string)
    max_connections_percent      = optional(number, 100)
    max_idle_connections_percent = optional(number, 50)
    session_pinning_filters      = optional(list(string), [])
  })
  default = {
    connection_borrow_timeout    = 120
    max_connections_percent      = 100
    max_idle_connections_percent = 50
    session_pinning_filters      = []
  }

  validation {
    condition = (
      var.connection_pool_config.connection_borrow_timeout >= 0 &&
      var.connection_pool_config.connection_borrow_timeout <= 3600
    )
    error_message = "Connection borrow timeout must be between 0 and 3600 seconds"
  }

  validation {
    condition = (
      var.connection_pool_config.max_connections_percent >= 1 &&
      var.connection_pool_config.max_connections_percent <= 100
    )
    error_message = "Max connections percent must be between 1 and 100"
  }

  validation {
    condition = (
      var.connection_pool_config.max_idle_connections_percent >= 0 &&
      var.connection_pool_config.max_idle_connections_percent <= 100
    )
    error_message = "Max idle connections percent must be between 0 and 100"
  }
}

# Target Database Configuration
variable "db_instance_identifier" {
  description = "RDS DB instance identifier (for single instance)"
  type        = string
  default     = null
}

variable "db_cluster_identifier" {
  description = "RDS DB cluster identifier (for Aurora)"
  type        = string
  default     = null
}

# CloudWatch Logs Configuration
variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch Logs for RDS Proxy"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention period in days"
  type        = number
  default     = 365

  validation {
    condition     = var.log_retention_days >= 90
    error_message = "Log retention must be at least 90 days for NIST compliance"
  }
}

# Encryption Configuration
variable "kms_key_id" {
  description = "ARN of KMS key for encrypting CloudWatch Logs and Secrets Manager"
  type        = string
  default     = null
}

# Security Controls
variable "security_controls" {
  description = "Security controls configuration from metadata module"
  type = object({
    encryption = object({
      require_kms_customer_managed  = bool
      require_encryption_at_rest    = bool
      require_encryption_in_transit = bool
      enable_kms_key_rotation       = bool
    })
    logging = object({
      require_cloudwatch_logs = bool
      min_log_retention_days  = number
      require_access_logging  = bool
      require_flow_logs       = bool
    })
    monitoring = object({
      enable_xray_tracing         = bool
      enable_enhanced_monitoring  = bool
      enable_performance_insights = bool
      require_cloudtrail          = bool
    })
    network = object({
      require_private_subnets = bool
      require_vpc_endpoints   = bool
      block_public_ingress    = bool
      require_imdsv2          = bool
    })
    compliance = object({
      enable_point_in_time_recovery = bool
      require_reserved_concurrency  = bool
      enable_deletion_protection    = bool
    })
  })
  default = null
}

# Security Control Overrides
variable "security_control_overrides" {
  description = <<-EOT
    Override specific security controls for this RDS Proxy.
    Only use when there's a documented business justification.
    
    Example use cases:
    - disable_kms_requirement: Development environments with IAM-only auth
    - disable_logging_requirement: Cost optimization for non-production
    - disable_private_subnet_requirement: Testing/development scenarios
    
    IMPORTANT: Document the reason in the 'justification' field for audit purposes.
  EOT

  type = object({
    disable_kms_requirement            = optional(bool, false)
    disable_logging_requirement        = optional(bool, false)
    disable_private_subnet_requirement = optional(bool, false)

    # Audit trail - document why controls are disabled
    justification = optional(string, "")
  })

  default = {
    disable_kms_requirement            = false
    disable_logging_requirement        = false
    disable_private_subnet_requirement = false
    justification                      = ""
  }
}
