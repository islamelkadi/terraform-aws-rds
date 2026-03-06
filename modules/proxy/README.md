# Terraform AWS RDS Proxy Module

This module creates an AWS RDS Proxy for connection pooling and improved database availability. RDS Proxy helps applications scale by pooling and sharing database connections, reducing database memory and CPU utilization.

## Features

- Connection pooling for improved database performance
- Automatic failover for high availability
- IAM authentication support
- Secrets Manager integration for credential management
- TLS encryption for connections
- CloudWatch Logs integration
- Configurable connection pool settings
- Support for both RDS instances and Aurora clusters

## Usage

### Basic Example (RDS Instance)

```hcl
module "rds_proxy" {
  source = "../../modules/terraform-aws-rds/modules/proxy"

  namespace   = "myorg"
  environment = "prod"
  name        = "myapp"
  region      = "us-east-1"

  engine_family = "POSTGRESQL"
  subnet_ids    = module.vpc.private_subnet_ids

  auth = [{
    auth_scheme = "SECRETS"
    description = "RDS credentials"
    iam_auth    = "DISABLED"
    secret_arn  = aws_secretsmanager_secret.db_credentials.arn
  }]

  db_instance_identifier = module.rds_instance.instance_id
  kms_key_id             = module.kms.key_arn

  tags = {
    Component = "DATABASE_PROXY"
    Purpose   = "CONNECTION_POOLING"
  }
}
```

### Aurora Cluster Example

```hcl
module "aurora_proxy" {
  source = "../../modules/terraform-aws-rds/modules/proxy"

  namespace   = "myorg"
  environment = "prod"
  name        = "myapp-aurora"
  region      = "us-east-1"

  engine_family = "POSTGRESQL"
  subnet_ids    = module.vpc.private_subnet_ids

  auth = [{
    auth_scheme = "SECRETS"
    description = "Aurora credentials"
    iam_auth    = "REQUIRED"
    secret_arn  = aws_secretsmanager_secret.aurora_credentials.arn
  }]

  db_cluster_identifier = module.aurora.cluster_id
  kms_key_id            = module.kms.key_arn

  # Custom connection pool settings
  connection_pool_config = {
    connection_borrow_timeout    = 120
    max_connections_percent      = 90
    max_idle_connections_percent = 40
    session_pinning_filters      = ["EXCLUDE_VARIABLE_SETS"]
  }

  tags = {
    Component = "DATABASE_PROXY"
    Purpose   = "CONNECTION_POOLING"
  }
}
```

### With IAM Authentication

```hcl
module "rds_proxy_iam" {
  source = "../../modules/terraform-aws-rds/modules/proxy"

  namespace   = "myorg"
  environment = "prod"
  name        = "myapp-iam"
  region      = "us-east-1"

  engine_family = "POSTGRESQL"
  subnet_ids    = module.vpc.private_subnet_ids

  auth = [{
    auth_scheme = "SECRETS"
    description = "RDS credentials with IAM"
    iam_auth    = "REQUIRED"
    secret_arn  = aws_secretsmanager_secret.db_credentials.arn
  }]

  db_instance_identifier = module.rds_instance.instance_id
  kms_key_id             = module.kms.key_arn
  require_tls            = true

  tags = {
    Component = "DATABASE_PROXY"
    Purpose   = "IAM_AUTHENTICATION"
  }
}
```

## Security Controls

This module implements security controls based on AWS Security Hub standards (FSBP, CIS, NIST 800-53, NIST 800-171, PCI DSS):

### Implemented Controls

- [x] Encryption in transit (TLS 1.2+ required by default)
- [x] CloudWatch Logs with 365-day retention
- [x] IAM role with least privilege (Secrets Manager access only)
- [x] Private subnet deployment (minimum 2 for HA)
- [x] KMS encryption for CloudWatch Logs
- [x] Security control override system with audit justification

### Security Control Overrides

The module supports selective disabling of security controls with documented justification:

```hcl
security_control_overrides = {
  disable_kms_requirement = true
  justification           = "Development environment with IAM-only authentication"
}
```

See [aws-security-standards.md](../../../../.kiro/steering/aws/aws-security-standards.md) for full security standards documentation.

## Connection Pooling Benefits

RDS Proxy provides several benefits:

1. **Reduced Connection Overhead**: Reuses database connections, reducing CPU and memory usage
2. **Improved Failover**: Automatically routes connections to healthy instances during failover
3. **IAM Authentication**: Centralized authentication without embedding credentials
4. **Connection Limits**: Prevents overwhelming the database with too many connections
5. **Monitoring**: CloudWatch metrics for connection pool health

## Session Pinning Filters

Session pinning filters prevent connection reuse for specific SQL operations:

- `EXCLUDE_VARIABLE_SETS`: Exclude connections that set session variables
- Default: `[]` (allow all connections to be reused)

## Example: Complete Setup with Secrets Manager

```hcl
# Create secret for database credentials
resource "aws_secretsmanager_secret" "db_credentials" {
  name       = "${var.namespace}-${var.environment}-db-credentials"
  kms_key_id = module.kms.key_arn
}

resource "aws_secretsmanager_secret_version" "db_credentials" {
  secret_id = aws_secretsmanager_secret.db_credentials.id
  secret_string = jsonencode({
    username = "dbadmin"
    password = random_password.db_password.result
  })
}

# Create RDS Proxy
module "rds_proxy" {
  source = "../../modules/terraform-aws-rds/modules/proxy"

  namespace   = var.namespace
  environment = var.environment
  name        = "myapp"
  region      = var.region

  engine_family = "POSTGRESQL"
  subnet_ids    = module.vpc.private_subnet_ids

  auth = [{
    auth_scheme = "SECRETS"
    description = "RDS credentials"
    iam_auth    = "DISABLED"
    secret_arn  = aws_secretsmanager_secret.db_credentials.arn
  }]

  db_instance_identifier = module.rds_instance.instance_id
  kms_key_id             = module.kms.key_arn

  tags = {
    Component = "DATABASE_PROXY"
  }
}

# Use proxy endpoint in application
resource "aws_lambda_function" "app" {
  # ...
  environment {
    variables = {
      DB_ENDPOINT = module.rds_proxy.proxy_endpoint
    }
  }
}
```

## License

Apache 2.0 Licensed. See [LICENSE](../../../../LICENSE) for full details.

## Environment-Based Security Controls

Security controls are automatically applied based on the environment through the [terraform-aws-metadata](https://github.com/islamelkadi/terraform-aws-metadata?tab=readme-ov-file#security-profiles){:target="_blank"} module's security profiles:

| Control | Dev | Staging | Prod |
|---------|-----|---------|------|
| KMS encryption at rest | Optional | Required | Required |
| IAM authentication | Optional | Recommended | Required |
| Connection pooling | Recommended | Required | Required |
| TLS enforcement | Required | Required | Required |

For full details on security profiles and how controls vary by environment, see the <a href="https://github.com/islamelkadi/terraform-aws-metadata?tab=readme-ov-file#security-profiles" target="_blank">Security Profiles</a> documentation.

<!-- BEGIN_TF_DOCS -->


## Usage

```hcl
# Basic RDS Proxy Example

module "rds_proxy" {
  source = "../"

  namespace   = var.namespace
  environment = var.environment
  name        = var.name
  region      = var.region

  engine_family = var.engine_family
  subnet_ids    = var.subnet_ids

  auth = [{
    auth_scheme = "SECRETS"
    description = "RDS credentials from Secrets Manager"
    iam_auth    = var.enable_iam_auth ? "REQUIRED" : "DISABLED"
    secret_arn  = var.secret_arn
  }]

  db_instance_identifier = var.db_instance_identifier
  kms_key_id             = var.kms_key_arn

  connection_pool_config = {
    connection_borrow_timeout    = 120
    max_connections_percent      = 100
    max_idle_connections_percent = 50
    session_pinning_filters      = []
  }

  enable_cloudwatch_logs = var.enable_cloudwatch_logs
  log_retention_days     = var.log_retention_days

  tags = var.tags
}
```

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
| <a name="module_metadata"></a> [metadata](#module\_metadata) | github.com/islamelkadi/terraform-aws-metadata | v1.1.0 |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.proxy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_db_proxy.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_proxy) | resource |
| [aws_db_proxy_default_target_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_proxy_default_target_group) | resource |
| [aws_db_proxy_target.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_proxy_target) | resource |
| [aws_db_proxy_target.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_proxy_target) | resource |
| [aws_iam_role.proxy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.proxy_secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_policy_document.proxy_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.proxy_secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_attributes"></a> [attributes](#input\_attributes) | Additional attributes for naming | `list(string)` | `[]` | no |
| <a name="input_auth"></a> [auth](#input\_auth) | Authentication configuration for RDS Proxy | <pre>list(object({<br/>    auth_scheme = optional(string, "SECRETS")<br/>    description = optional(string)<br/>    iam_auth    = optional(string, "DISABLED")<br/>    secret_arn  = optional(string)<br/>    username    = optional(string)<br/>  }))</pre> | n/a | yes |
| <a name="input_connection_pool_config"></a> [connection\_pool\_config](#input\_connection\_pool\_config) | Connection pool configuration for RDS Proxy | <pre>object({<br/>    connection_borrow_timeout    = optional(number, 120)<br/>    init_query                   = optional(string)<br/>    max_connections_percent      = optional(number, 100)<br/>    max_idle_connections_percent = optional(number, 50)<br/>    session_pinning_filters      = optional(list(string), [])<br/>  })</pre> | <pre>{<br/>  "connection_borrow_timeout": 120,<br/>  "max_connections_percent": 100,<br/>  "max_idle_connections_percent": 50,<br/>  "session_pinning_filters": []<br/>}</pre> | no |
| <a name="input_db_cluster_identifier"></a> [db\_cluster\_identifier](#input\_db\_cluster\_identifier) | RDS DB cluster identifier (for Aurora) | `string` | `null` | no |
| <a name="input_db_instance_identifier"></a> [db\_instance\_identifier](#input\_db\_instance\_identifier) | RDS DB instance identifier (for single instance) | `string` | `null` | no |
| <a name="input_debug_logging"></a> [debug\_logging](#input\_debug\_logging) | Enable detailed logging for debugging | `bool` | `false` | no |
| <a name="input_delimiter"></a> [delimiter](#input\_delimiter) | Delimiter to use between name components | `string` | `"-"` | no |
| <a name="input_enable_cloudwatch_logs"></a> [enable\_cloudwatch\_logs](#input\_enable\_cloudwatch\_logs) | Enable CloudWatch Logs for RDS Proxy | `bool` | `true` | no |
| <a name="input_engine_family"></a> [engine\_family](#input\_engine\_family) | Database engine family (MYSQL, POSTGRESQL, SQLSERVER) | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (dev, staging, prod) | `string` | n/a | yes |
| <a name="input_idle_client_timeout"></a> [idle\_client\_timeout](#input\_idle\_client\_timeout) | Number of seconds a connection can be idle before being closed (300-28800) | `number` | `1800` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | ARN of KMS key for encrypting CloudWatch Logs and Secrets Manager | `string` | `null` | no |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | CloudWatch Logs retention period in days | `number` | `365` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the RDS Proxy | `string` | n/a | yes |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace (organization/team name) | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region where resources will be created | `string` | n/a | yes |
| <a name="input_require_tls"></a> [require\_tls](#input\_require\_tls) | Require TLS for connections to RDS Proxy | `bool` | `true` | no |
| <a name="input_security_control_overrides"></a> [security\_control\_overrides](#input\_security\_control\_overrides) | Override specific security controls for this RDS Proxy.<br/>Only use when there's a documented business justification.<br/><br/>Example use cases:<br/>- disable\_kms\_requirement: Development environments with IAM-only auth<br/>- disable\_logging\_requirement: Cost optimization for non-production<br/>- disable\_private\_subnet\_requirement: Testing/development scenarios<br/><br/>IMPORTANT: Document the reason in the 'justification' field for audit purposes. | <pre>object({<br/>    disable_kms_requirement            = optional(bool, false)<br/>    disable_logging_requirement        = optional(bool, false)<br/>    disable_private_subnet_requirement = optional(bool, false)<br/><br/>    # Audit trail - document why controls are disabled<br/>    justification = optional(string, "")<br/>  })</pre> | <pre>{<br/>  "disable_kms_requirement": false,<br/>  "disable_logging_requirement": false,<br/>  "disable_private_subnet_requirement": false,<br/>  "justification": ""<br/>}</pre> | no |
| <a name="input_security_controls"></a> [security\_controls](#input\_security\_controls) | Security controls configuration from metadata module | <pre>object({<br/>    encryption = object({<br/>      require_kms_customer_managed  = bool<br/>      require_encryption_at_rest    = bool<br/>      require_encryption_in_transit = bool<br/>      enable_kms_key_rotation       = bool<br/>    })<br/>    logging = object({<br/>      require_cloudwatch_logs = bool<br/>      min_log_retention_days  = number<br/>      require_access_logging  = bool<br/>      require_flow_logs       = bool<br/>    })<br/>    monitoring = object({<br/>      enable_xray_tracing         = bool<br/>      enable_enhanced_monitoring  = bool<br/>      enable_performance_insights = bool<br/>      require_cloudtrail          = bool<br/>    })<br/>    network = object({<br/>      require_private_subnets = bool<br/>      require_vpc_endpoints   = bool<br/>      block_public_ingress    = bool<br/>      require_imdsv2          = bool<br/>    })<br/>    compliance = object({<br/>      enable_point_in_time_recovery = bool<br/>      require_reserved_concurrency  = bool<br/>      enable_deletion_protection    = bool<br/>    })<br/>  })</pre> | `null` | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | List of VPC subnet IDs for RDS Proxy (minimum 2 for HA) | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags to apply to resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_log_group_arn"></a> [log\_group\_arn](#output\_log\_group\_arn) | ARN of the CloudWatch Log Group (if enabled) |
| <a name="output_log_group_name"></a> [log\_group\_name](#output\_log\_group\_name) | Name of the CloudWatch Log Group (if enabled) |
| <a name="output_proxy_arn"></a> [proxy\_arn](#output\_proxy\_arn) | ARN of the RDS Proxy |
| <a name="output_proxy_endpoint"></a> [proxy\_endpoint](#output\_proxy\_endpoint) | Endpoint of the RDS Proxy |
| <a name="output_proxy_id"></a> [proxy\_id](#output\_proxy\_id) | ID of the RDS Proxy |
| <a name="output_proxy_name"></a> [proxy\_name](#output\_proxy\_name) | Name of the RDS Proxy |
| <a name="output_proxy_role_arn"></a> [proxy\_role\_arn](#output\_proxy\_role\_arn) | ARN of the IAM role used by the RDS Proxy |
| <a name="output_proxy_target_group_arn"></a> [proxy\_target\_group\_arn](#output\_proxy\_target\_group\_arn) | ARN of the RDS Proxy target group |
| <a name="output_proxy_target_group_name"></a> [proxy\_target\_group\_name](#output\_proxy\_target\_group\_name) | Name of the RDS Proxy target group |

## Example

See [example/](example/) for a complete working example with all features.

## License

MIT Licensed. See [LICENSE](LICENSE) for full details.
<!-- END_TF_DOCS -->
