# RDS Aurora PostgreSQL Module Outputs

output "cluster_id" {
  description = "Aurora cluster ID"
  value       = aws_rds_cluster.this.id
}

output "cluster_arn" {
  description = "Aurora cluster ARN"
  value       = aws_rds_cluster.this.arn
}

output "cluster_endpoint" {
  description = "Writer endpoint for the cluster"
  value       = aws_rds_cluster.this.endpoint
}

output "cluster_reader_endpoint" {
  description = "Reader endpoint for the cluster"
  value       = aws_rds_cluster.this.reader_endpoint
}

output "cluster_port" {
  description = "Port on which the database accepts connections"
  value       = aws_rds_cluster.this.port
}

output "cluster_database_name" {
  description = "Name of the default database"
  value       = aws_rds_cluster.this.database_name
}

output "cluster_master_username" {
  description = "Master username for the database"
  value       = aws_rds_cluster.this.master_username
  sensitive   = true
}

output "cluster_resource_id" {
  description = "Cluster resource ID"
  value       = aws_rds_cluster.this.cluster_resource_id
}

output "cluster_hosted_zone_id" {
  description = "Route53 hosted zone ID for the cluster endpoint"
  value       = aws_rds_cluster.this.hosted_zone_id
}

output "instance_ids" {
  description = "List of Aurora instance IDs"
  value       = aws_rds_cluster_instance.this[*].id
}

output "instance_endpoints" {
  description = "List of Aurora instance endpoints"
  value       = aws_rds_cluster_instance.this[*].endpoint
}

output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = aws_db_subnet_group.this.name
}

output "db_subnet_group_arn" {
  description = "ARN of the DB subnet group"
  value       = aws_db_subnet_group.this.arn
}

output "tags" {
  description = "Tags applied to the Aurora cluster"
  value       = aws_rds_cluster.this.tags
}
