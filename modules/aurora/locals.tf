# Local values for naming and tagging

locals {
  # Construct cluster name from components
  name_parts = compact(concat(
    [var.namespace],
    [var.environment],
    [var.name],
    var.naming_attributes
  ))

  cluster_name = join(var.delimiter, local.name_parts)

  # Merge tags with defaults
  tags = merge(
    var.tags,
    module.metadata.security_tags,
    {
      Name   = local.cluster_name
      Module = "terraform-aws-rds-aurora"
    }
  )
}
