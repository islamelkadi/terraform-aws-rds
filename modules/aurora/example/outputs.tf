# Example Outputs

output "cluster_endpoint" {
  description = "Aurora cluster writer endpoint"
  value       = module.aurora.cluster_endpoint
}

output "cluster_reader_endpoint" {
  description = "Aurora cluster reader endpoint"
  value       = module.aurora.cluster_reader_endpoint
}

output "cluster_arn" {
  description = "Aurora cluster ARN"
  value       = module.aurora.cluster_arn
}
