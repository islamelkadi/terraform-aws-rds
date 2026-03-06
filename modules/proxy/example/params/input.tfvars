namespace   = "example"
environment = "dev"
name        = "rds-proxy"
region      = "us-east-1"

engine_family          = "POSTGRESQL"
subnet_ids             = ["subnet-0a1b2c3d4e5f00001", "subnet-0a1b2c3d4e5f00002"]
secret_arn             = "arn:aws:secretsmanager:us-east-1:123456789012:secret:db-credentials-AbCdEf"
db_instance_identifier = "my-rds-instance"
kms_key_arn            = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"

enable_iam_auth        = false
enable_cloudwatch_logs = true
log_retention_days     = 90

tags = {
  Example = "RDS_PROXY"
}
