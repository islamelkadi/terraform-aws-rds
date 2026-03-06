# RDS Aurora PostgreSQL Module Variables

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
  description = "Name of the RDS Aurora cluster"
  type        = string
}

variable "naming_attributes" {
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

# Aurora cluster configuration
variable "engine_version" {
  description = "Aurora PostgreSQL engine version"
  type        = string
  default     = "15.4"
}

variable "database_name" {
  description = "Name of the default database to create"
  type        = string
}

variable "master_username" {
  description = "Master username for the database"
  type        = string
  default     = "postgres"
}

variable "master_password" {
  description = "Master password for the database. Use AWS Secrets Manager in production. Not required when IAM authentication is enabled"
  type        = string
  sensitive   = true
  default     = null
}

variable "enable_iam_database_authentication" {
  description = "Enable IAM database authentication for passwordless access"
  type        = bool
  default     = false
}

# Serverless v2 scaling configuration
variable "min_capacity" {
  description = "Minimum Aurora Capacity Units (ACU)"
  type        = number
  default     = 0.5

  validation {
    condition     = var.min_capacity >= 0.5 && var.min_capacity <= 128
    error_message = "Minimum capacity must be between 0.5 and 128 ACU"
  }
}

variable "max_capacity" {
  description = "Maximum Aurora Capacity Units (ACU)"
  type        = number
  default     = 2

  validation {
    condition     = var.max_capacity >= 0.5 && var.max_capacity <= 128
    error_message = "Maximum capacity must be between 0.5 and 128 ACU"
  }
}

# Network configuration
variable "subnet_ids" {
  description = "List of subnet IDs for the DB subnet group (should be private subnets)"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least 2 subnets in different AZs are required for Aurora"
  }
}

variable "vpc_security_group_ids" {
  description = "List of VPC security group IDs to associate with the cluster"
  type        = list(string)
}

# Encryption configuration
variable "kms_key_arn" {
  description = "ARN of KMS key for cluster encryption"
  type        = string
}

# Backup configuration
variable "backup_retention_period" {
  description = "Number of days to retain automated backups"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_period >= 1 && var.backup_retention_period <= 35
    error_message = "Backup retention period must be between 1 and 35 days"
  }
}

variable "preferred_backup_window" {
  description = "Daily time range for automated backups (UTC)"
  type        = string
  default     = "03:00-04:00"
}

variable "preferred_maintenance_window" {
  description = "Weekly time range for maintenance (UTC)"
  type        = string
  default     = "sun:04:00-sun:05:00"
}

# Instance configuration
variable "instance_count" {
  description = "Number of Aurora instances to create"
  type        = number
  default     = 1

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 15
    error_message = "Instance count must be between 1 and 15"
  }
}

# Monitoring configuration
variable "enable_performance_insights" {
  description = "Enable Performance Insights"
  type        = bool
  default     = true
}

variable "monitoring_interval" {
  description = "Enhanced monitoring interval in seconds (0, 1, 5, 10, 15, 30, 60)"
  type        = number
  default     = 60

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "Monitoring interval must be 0, 1, 5, 10, 15, 30, or 60 seconds"
  }
}

variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch (postgresql)"
  type        = list(string)
  default     = ["postgresql"]
}

# Protection configuration
variable "deletion_protection" {
  description = "Enable deletion protection for the cluster"
  type        = bool
  default     = false
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot when destroying cluster (set to false for production)"
  type        = bool
  default     = true
}

variable "apply_immediately" {
  description = "Apply changes immediately instead of during maintenance window"
  type        = bool
  default     = false
}

variable "region" {
  description = "AWS region where resources will be created"
  type        = string
}

# Security controls
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
    high_availability = object({
      require_multi_az    = bool
      require_nat_gateway = bool
    })
    data_protection = object({
      require_versioning  = bool
      require_mfa_delete  = bool
      require_backup      = bool
      require_lifecycle   = bool
      block_public_access = bool
      require_replication = bool
    })
  })
  default = null
}

variable "security_control_overrides" {
  description = "Override specific security controls with documented justification"
  type = object({
    disable_kms_requirement      = optional(bool, false)
    disable_performance_insights = optional(bool, false)
    disable_enhanced_monitoring  = optional(bool, false)
    disable_multi_az_requirement = optional(bool, false)
    disable_backup_requirement   = optional(bool, false)
    disable_deletion_protection  = optional(bool, false)
    justification                = optional(string, "")
  })
  default = {
    disable_kms_requirement      = false
    disable_performance_insights = false
    disable_enhanced_monitoring  = false
    disable_multi_az_requirement = false
    disable_backup_requirement   = false
    disable_deletion_protection  = false
    justification                = ""
  }
}
