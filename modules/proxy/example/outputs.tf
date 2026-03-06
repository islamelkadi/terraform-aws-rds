# Example Outputs

output "proxy_endpoint" {
  description = "RDS Proxy endpoint for database connections"
  value       = module.rds_proxy.proxy_endpoint
}

output "proxy_arn" {
  description = "ARN of the RDS Proxy"
  value       = module.rds_proxy.proxy_arn
}

output "proxy_name" {
  description = "Name of the RDS Proxy"
  value       = module.rds_proxy.proxy_name
}
