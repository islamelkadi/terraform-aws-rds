# Basic RDS Proxy Example

This example creates an RDS Proxy for connection pooling using fictitious subnet, secret, and KMS key ARNs.

## Usage

```bash
terraform init
terraform plan -var-file=params/input.tfvars
terraform apply -var-file=params/input.tfvars
```

## What This Example Creates

- RDS Proxy with connection pooling for PostgreSQL
- CloudWatch Log Group for proxy logs

## Prerequisites

- Existing RDS instance
- Existing Secrets Manager secret with database credentials
- Existing KMS key for encryption

## Clean Up

```bash
terraform destroy -var-file=params/input.tfvars
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.14.3 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 6.34.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_kms_key"></a> [kms\_key](#module\_kms\_key) | git::https://github.com/islamelkadi/terraform-aws-kms.git | v1.0.0 |
| <a name="module_rds_proxy"></a> [rds\_proxy](#module\_rds\_proxy) | ../ | n/a |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | git::https://github.com/islamelkadi/terraform-aws-vpc.git//modules/vpc | v1.0.0 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_db_instance_identifier"></a> [db\_instance\_identifier](#input\_db\_instance\_identifier) | Identifier of the RDS instance | `string` | `"my-rds-instance"` | no |
| <a name="input_enable_cloudwatch_logs"></a> [enable\_cloudwatch\_logs](#input\_enable\_cloudwatch\_logs) | Enable CloudWatch Logs for the proxy | `bool` | `true` | no |
| <a name="input_enable_iam_auth"></a> [enable\_iam\_auth](#input\_enable\_iam\_auth) | Enable IAM authentication | `bool` | `false` | no |
| <a name="input_engine_family"></a> [engine\_family](#input\_engine\_family) | Database engine family (MYSQL, POSTGRESQL, SQLSERVER) | `string` | `"POSTGRESQL"` | no |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name | `string` | `"dev"` | no |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | CloudWatch Logs retention in days | `number` | `7` | no |
| <a name="input_name"></a> [name](#input\_name) | Name for the RDS Proxy | `string` | `"rds-proxy"` | no |
| <a name="input_namespace"></a> [namespace](#input\_namespace) | Namespace (organization/team name) | `string` | `"example"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region | `string` | `"us-east-1"` | no |
| <a name="input_secret_arn"></a> [secret\_arn](#input\_secret\_arn) | ARN of the Secrets Manager secret for database credentials | `string` | `"arn:aws:secretsmanager:us-east-1:123456789012:secret:db-credentials-AbCdEf"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Additional tags | `map(string)` | <pre>{<br/>  "Example": "RDS_PROXY"<br/>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_proxy_arn"></a> [proxy\_arn](#output\_proxy\_arn) | ARN of the RDS Proxy |
| <a name="output_proxy_endpoint"></a> [proxy\_endpoint](#output\_proxy\_endpoint) | RDS Proxy endpoint for database connections |
| <a name="output_proxy_name"></a> [proxy\_name](#output\_proxy\_name) | Name of the RDS Proxy |
<!-- END_TF_DOCS -->