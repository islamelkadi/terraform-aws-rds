# Terraform AWS RDS Module

Reusable Terraform module for AWS RDS with Aurora Serverless v2 and RDS Proxy submodules.

## Prerequisites

This module is designed for macOS. The following must already be installed on your machine:
- Python 3 and pip
- [Kiro](https://kiro.dev) and Kiro CLI
- [Homebrew](https://brew.sh)

To install the remaining development tools, run:

```bash
make bootstrap
```

This will install/upgrade: tfenv, Terraform (via tfenv), tflint, terraform-docs, checkov, and pre-commit.

## Submodules

| Submodule | Description |
|-----------|-------------|
| [aurora](modules/aurora/) | Aurora Serverless v2 PostgreSQL cluster |
| [proxy](modules/proxy/) | RDS Proxy for connection pooling |

## Usage

```hcl
module "aurora" {
  source = "path/to/terraform-aws-rds/modules/aurora"

  namespace   = "example"
  environment = "prod"
  name        = "corporate-actions"
  region      = "us-east-1"

  database_name   = "corporate_actions_db"
  master_username = "postgres"
  master_password = var.master_password

  subnet_ids             = var.subnet_ids
  vpc_security_group_ids = var.vpc_security_group_ids
  kms_key_arn            = var.kms_key_arn

  min_capacity   = 0.5
  max_capacity   = 4
  instance_count = 2

  tags = var.tags
}
```

## Security Controls

Implements controls for FSBP, CIS, NIST 800-53/171, and PCI DSS v4.0:

- Encryption at rest with KMS customer-managed keys
- Automated encrypted backups with configurable retention
- Performance Insights and enhanced monitoring
- Multi-AZ high availability
- Deletion protection
- Security control overrides with audit justification

## Module Structure

```
terraform-aws-rds/
├── modules/
│   ├── aurora/
│   │   ├── example/
│   │   │   ├── main.tf
│   │   │   ├── variables.tf
│   │   │   ├── outputs.tf
│   │   │   └── params/input.tfvars
│   │   └── ...
│   └── proxy/
│       ├── example/
│       │   ├── main.tf
│       │   ├── variables.tf
│       │   ├── outputs.tf
│       │   └── params/input.tfvars
│       └── ...
└── README.md
```

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.14.3 |
| aws | >= 6.34 |

## Environment-Based Security Controls

Security controls are automatically applied based on the environment through the [terraform-aws-metadata](https://github.com/islamelkadi/terraform-aws-metadata?tab=readme-ov-file#security-profiles){:target="_blank"} module's security profiles:

| Control | Dev | Staging | Prod |
|---------|-----|---------|------|
| KMS encryption at rest | Optional | Required | Required |
| Automated backups | Optional | Required | Required |
| Performance Insights | Optional | Enabled | Enabled |
| Multi-AZ | Disabled | Enabled | Enabled |
| Deletion protection | Disabled | Enabled | Enabled |
| Enhanced monitoring | Optional | Recommended | Required |

For full details on security profiles and how controls vary by environment, see the <a href="https://github.com/islamelkadi/terraform-aws-metadata?tab=readme-ov-file#security-profiles" target="_blank">Security Profiles</a> documentation.

## MCP Servers

This module includes two [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) servers configured in `.kiro/settings/mcp.json` for use with Kiro:

| Server | Package | Description |
|--------|---------|-------------|
| `aws-docs` | `awslabs.aws-documentation-mcp-server@latest` | Provides access to AWS documentation for contextual lookups of service features, API references, and best practices. |
| `terraform` | `awslabs.terraform-mcp-server@latest` | Enables Terraform operations (init, validate, plan, fmt, tflint) directly from the IDE with auto-approved commands for common workflows. |

Both servers run via `uvx` and require no additional installation beyond the [bootstrap](#prerequisites) step.

<!-- BEGIN_TF_DOCS -->


## Requirements

No requirements.

## Providers

No providers.

## Modules

No modules.

## Resources

No resources.

## Inputs

No inputs.

## Outputs

No outputs.

## License

MIT Licensed. See [LICENSE](LICENSE) for full details.
<!-- END_TF_DOCS -->
