# Terraform AWS RDS Aurora PostgreSQL Module

Production-ready AWS Aurora PostgreSQL Serverless v2 module with comprehensive security controls, automated backups, performance monitoring, and high availability support. Optimized for cost-effective scaling with enterprise-grade reliability.

## Table of Contents

- [Security](#security)
- [Features](#features)
- [Usage Examples](#usage-examples)
- [Requirements](#requirements)
- [Examples](#examples)

## Features

- **Serverless v2 Scaling**: Automatic capacity scaling from 0.5 to 128 ACU
- **KMS Encryption**: Customer-managed key encryption at rest
- **Automated Backups**: Configurable retention period (1-35 days)
- **Performance Insights**: Query performance monitoring and analysis
- **Enhanced Monitoring**: CloudWatch Logs integration for PostgreSQL logs
- **Multi-AZ Support**: High availability across multiple availability zones
- **Deletion Protection**: Optional protection against accidental deletion
- **IAM Integration**: Enhanced monitoring IAM role with least privilege
- **Consistent Naming**: Integration with metadata module for standardized resource naming

## Security

### Security Improvements

This module now implements enhanced security by default:

- ✅ **IAM Database Authentication**: Enabled by default for passwordless access
- ✅ **Auto Minor Version Upgrades**: Enabled by default for automatic security patches
- ✅ **Multi-AZ Deployment**: 2 instances by default for high availability
- ✅ **Private Subnet Validation**: Ensures RDS is never deployed in public subnets
- ✅ **CloudWatch Log Retention**: 365 days by default with environment-based validation
- ✅ **Deletion Protection**: Enabled by default (true) for production safety

### Security Controls

This module implements security controls based on the metadata module's security policy. Controls can be selectively overridden with documented business justification.

### Available Security Control Overrides

| Override Flag | Control | Default | Common Use Case |
|--------------|---------|---------|-----------------|
| `disable_kms_requirement` | KMS Customer-Managed Encryption | `false` | Development databases with no sensitive data |
| `disable_performance_insights` | Performance Insights | `false` | Cost optimization in dev/test environments |
| `disable_enhanced_monitoring` | CloudWatch Logs Export | `false` | Development databases with minimal monitoring needs |
| `disable_multi_az_requirement` | Multi-AZ Deployment | `false` | Development databases where downtime is acceptable |
| `disable_backup_requirement` | Automated Backups | `false` | Ephemeral test databases with disposable data |
| `disable_deletion_protection` | Deletion Protection | `false` | Development databases requiring frequent recreation |

### Security Control Architecture

**Two-Layer Design:**
1. **Metadata Module** (Policy Layer): Defines security requirements based on environment
2. **RDS Aurora Module** (Enforcement Layer): Validates configuration against policy

**Override Pattern:**
```hcl
security_control_overrides = {
  disable_multi_az_requirement = true
  disable_deletion_protection  = true
  justification = "Development database, downtime acceptable, frequent recreation required"
}
```

### Best Practices

1. **Production Databases**: Never override encryption, backups, or multi-AZ without approval
2. **Development Databases**: Overrides acceptable for cost optimization with justification
3. **Sensitive Data**: Always use KMS customer-managed keys regardless of environment
4. **Audit Trail**: All overrides require `justification` field for compliance
5. **Review Cycle**: Quarterly review of all active overrides

### Environment-Based Security Controls

Security controls are automatically applied based on the environment through the [terraform-aws-metadata](https://github.com/islamelkadi/terraform-aws-metadata?tab=readme-ov-file#security-profiles) module's security profiles:

| Control | Dev | Staging | Prod |
|---------|-----|---------|------|
| KMS encryption at rest | Optional | Required | Required |
| Automated backups | Optional | Required | Required |
| Performance Insights | Optional | Enabled | Enabled |
| Multi-AZ | Disabled | Enabled | Enabled |
| Deletion protection | Disabled | Enabled | Enabled |
| Enhanced monitoring | Optional | Recommended | Required |

For full details on security profiles and how controls vary by environment, see the [Security Profiles](https://github.com/islamelkadi/terraform-aws-metadata?tab=readme-ov-file#security-profiles) documentation.
## Usage Examples

### Example 1: Basic Aurora Cluster with Security Controls

```hcl
module "metadata" {
  source = "github.com/islamelkadi/terraform-aws-metadata"
  
  namespace   = "example"
  environment = "prod"
  name        = "corporate-actions"
  region      = "us-east-1"
}

module "aurora" {
  source = "github.com/islamelkadi/terraform-aws-rds//modules/aurora"
  
  namespace   = module.metadata.namespace
  environment = module.metadata.environment
  name        = "positions"
  region      = module.metadata.region
  
  database_name   = "positions"
  master_username = "postgres"
  master_password = data.aws_secretsmanager_secret_version.db_password.secret_string
  
  engine_version = "15.4"
  instance_count = 2  # Multi-AZ
  
  min_capacity = 0.5
  max_capacity = 4
  
  subnet_ids             = module.vpc.database_subnet_ids
  vpc_security_group_ids = [module.security_group.id]
  kms_key_arn            = module.kms.key_arn
  
  backup_retention_period = 7
  deletion_protection     = true
  
  security_controls = module.metadata.security_controls
  
  tags = module.metadata.tags
}
```

### Example 2: Production Aurora with Maximum Security

```hcl
module "aurora" {
  source = "github.com/islamelkadi/terraform-aws-rds//modules/aurora"
  
  namespace   = "example"
  environment = "prod"
  name        = "transactions"
  region      = "us-east-1"
  
  database_name   = "transactions"
  master_username = "postgres"
  master_password = data.aws_secretsmanager_secret_version.db_password.secret_string
  
  engine_version = "15.4"
  instance_count = 3  # Three instances for maximum availability
  
  # Production scaling configuration
  min_capacity = 2
  max_capacity = 16
  
  subnet_ids             = module.vpc.database_subnet_ids
  vpc_security_group_ids = [module.security_group.id]
  kms_key_arn            = module.kms.key_arn
  
  # Extended backup retention for compliance
  backup_retention_period = 35
  skip_final_snapshot     = false
  
  # Maximum protection
  deletion_protection = true
  apply_immediately   = false
  
  # Enhanced monitoring
  enable_performance_insights = true
  monitoring_interval         = 60
  enabled_cloudwatch_logs_exports = ["postgresql"]
  
  # Maintenance windows
  preferred_backup_window      = "03:00-04:00"
  preferred_maintenance_window = "sun:04:00-sun:05:00"
  
  security_controls = module.metadata.security_controls
  
  tags = merge(
    module.metadata.tags,
    {
      Tier = "Data"
      Compliance = "FCAC"
      Criticality = "High"
    }
  )
}
```

### Example 3: Development Aurora with Cost Optimization

```hcl
module "aurora" {
  source = "github.com/islamelkadi/terraform-aws-rds//modules/aurora"
  
  namespace   = "example"
  environment = "dev"
  name        = "development"
  region      = "us-east-1"
  
  database_name   = "devdb"
  master_username = "postgres"
  master_password = "ChangeMe123!"  # Use Secrets Manager in production
  
  engine_version = "15.4"
  instance_count = 1  # Single instance for cost savings
  
  # Minimal capacity for development
  min_capacity = 0.5
  max_capacity = 2
  
  subnet_ids             = module.vpc.database_subnet_ids
  vpc_security_group_ids = [module.security_group.id]
  kms_key_arn            = module.kms.key_arn
  
  # Minimal backup retention
  backup_retention_period = 1
  skip_final_snapshot     = true
  
  # No deletion protection for dev
  deletion_protection = false
  apply_immediately   = true
  
  # Reduced monitoring
  enable_performance_insights = false
  monitoring_interval         = 0
  
  security_controls = module.metadata.security_controls
  
  # Override with justification
  security_control_overrides = {
    disable_multi_az_requirement = true
    disable_deletion_protection  = true
    disable_performance_insights = true
    disable_enhanced_monitoring  = true
    justification = "Development database, downtime acceptable, cost optimization required"
  }
  
  tags = module.metadata.tags
}
```

### Example 4: Test Database with Minimal Configuration

```hcl
module "aurora" {
  source = "github.com/islamelkadi/terraform-aws-rds//modules/aurora"
  
  namespace   = "example"
  environment = "dev"
  name        = "integration-test"
  region      = "us-east-1"
  
  database_name   = "testdb"
  master_username = "postgres"
  master_password = "TestPassword123!"
  
  engine_version = "15.4"
  instance_count = 1
  
  min_capacity = 0.5
  max_capacity = 1
  
  subnet_ids             = module.vpc.database_subnet_ids
  vpc_security_group_ids = [module.security_group.id]
  kms_key_arn            = module.kms.key_arn
  
  # Minimal settings for ephemeral test database
  backup_retention_period = 1
  skip_final_snapshot     = true
  deletion_protection     = false
  
  enable_performance_insights = false
  monitoring_interval         = 0
  
  security_controls = module.metadata.security_controls
  
  # Multiple overrides for test environment
  security_control_overrides = {
    disable_multi_az_requirement = true
    disable_deletion_protection  = true
    disable_performance_insights = true
    disable_enhanced_monitoring  = true
    disable_backup_requirement   = true
    justification = "Ephemeral integration test database, data is disposable, recreated frequently"
  }
  
  tags = module.metadata.tags
}
```

<!-- BEGIN_TF_DOCS -->


## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.14.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.34 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 6.34 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_metadata"></a> [metadata](#module\_metadata) | github.com/islamelkadi/terraform-aws-metadata | v1.0.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.aurora_logs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_db_subnet_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [aws_iam_role.rds_monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.rds_monitoring](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_rds_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster) | resource |
| [aws_rds_cluster_instance.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster_instance) | resource |
| [aws_iam_policy_document.rds_monitoring_assume](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_subnet.selected](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/subnet) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_apply_immediately"></a> [apply\_immediately](#input\_apply\_immediately) | Apply changes immediately instead of during maintenance window | `bool` | `false` | no |
| <a name="input_auto_minor_version_upgrade"></a> [auto\_minor\_version\_upgrade](#input\_auto\_minor\_version\_upgrade) | Enable automatic minor version upgrades for security patches (recommended) | `bool` | `true` | no |
| <a name="input_backup_retention_period"></a> [backup\_retention\_period](#input\_backup\_retention\_period) | Number of days to retain automated backups | `number` | `7` | no |
| <a name="input_database_name"></a> [database\_name](#input\_database\_name) | Name of the default database to create | `string` | n/a | yes |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | Enable deletion protection for the cluster (required parameter - set based on environment needs) | `bool` | `true` | no |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | Delimiter to use between name components | `string` | `"-"` | no |
| <a name="input_enable_iam_database_authentication"></a> [enable\_iam\_database\_authentication](#input\_enable\_iam\_database\_authentication) | Enable IAM database authentication for passwordless access (recommended for security) | `bool` | `true` | no |
| <a name="input_enable_performance_insights"></a> [enable\_performance\_insights](#input\_enable\_performance\_insights) | Enable Performance Insights | `bool` | `true` | no |
| <a name="input_enabled_cloudwatch_logs_exports"></a> [enabled\_cloudwatch\_logs\_exports](#input\_enabled\_cloudwatch\_logs\_exports) | List of log types to export to CloudWatch (postgresql) | `list(string)` | <pre>[<br/>  "postgresql"<br/>]</pre> | no |
| <a name="input_engine_version"></a> [engine\_version](#input\_engine\_version) | Aurora PostgreSQL engine version | `string` | `"15.4"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, staging, prod) | `string` | n/a | yes |
| <a name="input_instance_count"></a> [instance\_count](#input\_instance\_count) | Number of Aurora instances to create (minimum 2 for Multi-AZ high availability) | `number` | `2` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | ARN of KMS key for cluster encryption | `string` | n/a | yes |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | Number of days to retain CloudWatch logs (365 days recommended for production) | `number` | `365` | no |
| <a name="input_master_password"></a> [master\_password](#input\_master\_password) | Master password for the database. Use AWS Secrets Manager in production. Not required when IAM authentication is enabled | `string` | `null` | no |
| <a name="input_master_username"></a> [master\_username](#input\_master\_username) | Master username for the database | `string` | `"postgres"` | no |
| <a name="input_max_capacity"></a> [max\_capacity](#input\_max\_capacity) | Maximum Aurora Capacity Units (ACU) | `number` | `2` | no |
| <a name="input_min_capacity"></a> [min\_capacity](#input\_min\_capacity) | Minimum Aurora Capacity Units (ACU) | `number` | `0.5` | no |
| <a name="input_monitoring_interval"></a> [monitoring\_interval](#input\_monitoring\_interval) | Enhanced monitoring interval in seconds (0, 1, 5, 10, 15, 30, 60) | `number` | `60` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the RDS Aurora cluster | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace (organization/team name) | `string` | n/a | yes |
| <a name="input_naming_attributes"></a> [naming\_attributes](#input\_naming\_attributes) | Additional attributes for naming | `list(string)` | `[]` | no |
| <a name="input_preferred_backup_window"></a> [preferred\_backup\_window](#input\_preferred\_backup\_window) | Daily time range for automated backups (UTC) | `string` | `"03:00-04:00"` | no |
| <a name="input_preferred_maintenance_window"></a> [preferred\_maintenance\_window](#input\_preferred\_maintenance\_window) | Weekly time range for maintenance (UTC) | `string` | `"sun:04:00-sun:05:00"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region where resources will be created | `string` | n/a | yes |
| <a name="input_security_control_overrides"></a> [security\_control\_overrides](#input\_security\_control\_overrides) | Override specific security controls with documented justification | <pre>object({<br/>    disable_kms_requirement      = optional(bool, false)<br/>    disable_performance_insights = optional(bool, false)<br/>    disable_enhanced_monitoring  = optional(bool, false)<br/>    disable_multi_az_requirement = optional(bool, false)<br/>    disable_backup_requirement   = optional(bool, false)<br/>    disable_deletion_protection  = optional(bool, false)<br/>    justification                = optional(string, "")<br/>  })</pre> | <pre>{<br/>  "disable_backup_requirement": false,<br/>  "disable_deletion_protection": false,<br/>  "disable_enhanced_monitoring": false,<br/>  "disable_kms_requirement": false,<br/>  "disable_multi_az_requirement": false,<br/>  "disable_performance_insights": false,<br/>  "justification": ""<br/>}</pre> | no |
| <a name="input_security_controls"></a> [security\_controls](#input\_security\_controls) | Security controls configuration from metadata module | <pre>object({<br/>    encryption = object({<br/>      require_kms_customer_managed  = bool<br/>      require_encryption_at_rest    = bool<br/>      require_encryption_in_transit = bool<br/>      enable_kms_key_rotation       = bool<br/>    })<br/>    logging = object({<br/>      require_cloudwatch_logs = bool<br/>      min_log_retention_days  = number<br/>      require_access_logging  = bool<br/>      require_flow_logs       = bool<br/>    })<br/>    monitoring = object({<br/>      enable_xray_tracing         = bool<br/>      enable_enhanced_monitoring  = bool<br/>      enable_performance_insights = bool<br/>      require_cloudtrail          = bool<br/>    })<br/>    network = object({<br/>      require_private_subnets = bool<br/>      require_vpc_endpoints   = bool<br/>      block_public_ingress    = bool<br/>      require_imdsv2          = bool<br/>    })<br/>    compliance = object({<br/>      enable_point_in_time_recovery = bool<br/>      require_reserved_concurrency  = bool<br/>      enable_deletion_protection    = bool<br/>    })<br/>    high_availability = object({<br/>      require_multi_az    = bool<br/>      require_nat_gateway = bool<br/>    })<br/>    data_protection = object({<br/>      require_versioning  = bool<br/>      require_mfa_delete  = bool<br/>      require_backup      = bool<br/>      require_lifecycle   = bool<br/>      block_public_access = bool<br/>      require_replication = bool<br/>    })<br/>  })</pre> | `null` | no |
| <a name="input_skip_final_snapshot"></a> [skip\_final\_snapshot](#input\_skip\_final\_snapshot) | Skip final snapshot when destroying cluster (set to false for production) | `bool` | `true` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | List of subnet IDs for the DB subnet group (should be private subnets) | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to apply to resources | `map(string)` | `{}` | no |
| <a name="input_vpc_security_group_ids"></a> [vpc\_security\_group\_ids](#input\_vpc\_security\_group\_ids) | List of VPC security group IDs to associate with the cluster | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_arn"></a> [cluster\_arn](#output\_cluster\_arn) | Aurora cluster ARN |
| <a name="output_cluster_database_name"></a> [cluster\_database\_name](#output\_cluster\_database\_name) | Name of the default database |
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | Writer endpoint for the cluster |
| <a name="output_cluster_hosted_zone_id"></a> [cluster\_hosted\_zone\_id](#output\_cluster\_hosted\_zone\_id) | Route53 hosted zone ID for the cluster endpoint |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | Aurora cluster ID |
| <a name="output_cluster_master_username"></a> [cluster\_master\_username](#output\_cluster\_master\_username) | Master username for the database |
| <a name="output_cluster_port"></a> [cluster\_port](#output\_cluster\_port) | Port on which the database accepts connections |
| <a name="output_cluster_reader_endpoint"></a> [cluster\_reader\_endpoint](#output\_cluster\_reader\_endpoint) | Reader endpoint for the cluster |
| <a name="output_cluster_resource_id"></a> [cluster\_resource\_id](#output\_cluster\_resource\_id) | Cluster resource ID |
| <a name="output_db_subnet_group_arn"></a> [db\_subnet\_group\_arn](#output\_db\_subnet\_group\_arn) | ARN of the DB subnet group |
| <a name="output_db_subnet_group_name"></a> [db\_subnet\_group\_name](#output\_db\_subnet\_group\_name) | Name of the DB subnet group |
| <a name="output_instance_endpoints"></a> [instance\_endpoints](#output\_instance\_endpoints) | List of Aurora instance endpoints |
| <a name="output_instance_ids"></a> [instance\_ids](#output\_instance\_ids) | List of Aurora instance IDs |
| <a name="output_tags"></a> [tags](#output\_tags) | Tags applied to the Aurora cluster |

## License

MIT Licensed. See [LICENSE](LICENSE) for full details.
<!-- END_TF_DOCS -->
