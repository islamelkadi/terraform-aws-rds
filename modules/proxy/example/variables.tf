variable "namespace" {
  description = "Namespace (organization/team name)"
  type        = string
  default     = "example"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "dev"
}

variable "name" {
  description = "Name for the RDS Proxy"
  type        = string
  default     = "rds-proxy"
}

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "engine_family" {
  description = "Database engine family (MYSQL, POSTGRESQL, SQLSERVER)"
  type        = string
  default     = "POSTGRESQL"
}

variable "secret_arn" {
  description = "ARN of the Secrets Manager secret for database credentials"
  type        = string
  default     = "arn:aws:secretsmanager:us-east-1:123456789012:secret:db-credentials-AbCdEf"
}

variable "db_instance_identifier" {
  description = "Identifier of the RDS instance"
  type        = string
  default     = "my-rds-instance"
}

variable "enable_iam_auth" {
  description = "Enable IAM authentication"
  type        = bool
  default     = false
}

variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch Logs for the proxy"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "CloudWatch Logs retention in days"
  type        = number
  default     = 7
}

variable "tags" {
  description = "Additional tags"
  type        = map(string)
  default = {
    Example = "RDS_PROXY"
  }
}
