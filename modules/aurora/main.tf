# RDS Aurora PostgreSQL Module
# Creates AWS RDS Aurora Serverless v2 cluster with encryption, automated backups, and security

# DB Subnet Group
resource "aws_db_subnet_group" "this" {
  name       = "${local.cluster_name}-subnet-group"
  subnet_ids = var.subnet_ids

  tags = merge(
    local.tags,
    {
      Name = "${local.cluster_name}-subnet-group"
    }
  )
}

# Aurora Cluster
resource "aws_rds_cluster" "this" {
  cluster_identifier = local.cluster_name
  engine             = "aurora-postgresql"
  engine_mode        = "provisioned"
  engine_version     = var.engine_version
  database_name      = var.database_name
  master_username    = var.master_username
  master_password    = var.enable_iam_database_authentication ? null : var.master_password

  # Enable IAM database authentication
  iam_database_authentication_enabled = var.enable_iam_database_authentication

  # Serverless v2 scaling configuration
  serverlessv2_scaling_configuration {
    min_capacity = var.min_capacity
    max_capacity = var.max_capacity
  }

  # Network configuration
  db_subnet_group_name   = aws_db_subnet_group.this.name
  vpc_security_group_ids = var.vpc_security_group_ids

  # Encryption at rest with KMS
  storage_encrypted = true
  kms_key_id        = var.kms_key_arn

  # Automated backups
  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = var.preferred_backup_window
  preferred_maintenance_window = var.preferred_maintenance_window

  # Enable deletion protection for production
  deletion_protection = var.deletion_protection

  # Skip final snapshot for demo/dev environments
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${local.cluster_name}-final-snapshot-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # Enable CloudWatch logs export
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  # Apply changes immediately for demo
  apply_immediately = var.apply_immediately

  tags = local.tags
}

# Aurora Serverless v2 Instance
resource "aws_rds_cluster_instance" "this" {
  count = var.instance_count

  identifier         = "${local.cluster_name}-instance-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.this.id
  instance_class     = "db.serverless"
  engine             = aws_rds_cluster.this.engine
  engine_version     = aws_rds_cluster.this.engine_version

  # Performance Insights
  performance_insights_enabled    = var.enable_performance_insights
  performance_insights_kms_key_id = var.enable_performance_insights ? var.kms_key_arn : null

  # Monitoring
  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_interval > 0 ? aws_iam_role.rds_monitoring[0].arn : null

  # Apply changes immediately for demo
  apply_immediately = var.apply_immediately

  tags = merge(
    local.tags,
    {
      Name = "${local.cluster_name}-instance-${count.index + 1}"
    }
  )
}

# IAM role for enhanced monitoring
data "aws_iam_policy_document" "rds_monitoring_assume" {
  count = var.monitoring_interval > 0 ? 1 : 0

  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["monitoring.rds.amazonaws.com"]
    }

    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role" "rds_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  name               = "${local.cluster_name}-monitoring-role"
  assume_role_policy = data.aws_iam_policy_document.rds_monitoring_assume[0].json

  tags = local.tags
}

resource "aws_iam_role_policy_attachment" "rds_monitoring" {
  count = var.monitoring_interval > 0 ? 1 : 0

  role       = aws_iam_role.rds_monitoring[0].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonRDSEnhancedMonitoringRole"
}
