# RDS Proxy Module Outputs

output "proxy_id" {
  description = "ID of the RDS Proxy"
  value       = aws_db_proxy.this.id
}

output "proxy_arn" {
  description = "ARN of the RDS Proxy"
  value       = aws_db_proxy.this.arn
}

output "proxy_endpoint" {
  description = "Endpoint of the RDS Proxy"
  value       = aws_db_proxy.this.endpoint
}

output "proxy_name" {
  description = "Name of the RDS Proxy"
  value       = aws_db_proxy.this.name
}

output "proxy_role_arn" {
  description = "ARN of the IAM role used by the RDS Proxy"
  value       = aws_iam_role.proxy.arn
}

output "proxy_target_group_name" {
  description = "Name of the RDS Proxy target group"
  value       = aws_db_proxy_default_target_group.this.name
}

output "proxy_target_group_arn" {
  description = "ARN of the RDS Proxy target group"
  value       = aws_db_proxy_default_target_group.this.arn
}

output "log_group_name" {
  description = "Name of the CloudWatch Log Group (if enabled)"
  value       = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.proxy[0].name : null
}

output "log_group_arn" {
  description = "ARN of the CloudWatch Log Group (if enabled)"
  value       = var.enable_cloudwatch_logs ? aws_cloudwatch_log_group.proxy[0].arn : null
}
