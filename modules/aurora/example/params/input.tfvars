namespace   = "example"
environment = "dev"
name        = "corporate-actions"
region      = "us-east-1"

database_name   = "corporate_actions_db"
master_username = "postgres"
master_password = "change-me-use-secrets-manager"

subnet_ids             = ["subnet-0a1b2c3d4e5f00001", "subnet-0a1b2c3d4e5f00002"]
vpc_security_group_ids = ["sg-0a1b2c3d4e5f67890"]
kms_key_arn            = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

min_capacity = 0.5
max_capacity = 4

backup_retention_period      = 14
preferred_backup_window      = "03:00-04:00"
preferred_maintenance_window = "sun:04:00-sun:05:00"

instance_count = 2

enable_performance_insights     = true
monitoring_interval             = 60
enabled_cloudwatch_logs_exports = ["postgresql"]

deletion_protection = false
skip_final_snapshot = true
apply_immediately   = true

tags = {
  Project = "corporate-actions"
}
