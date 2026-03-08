# Terraform AWS RDS Module

Reusable Terraform module for AWS RDS with Aurora Serverless v2 and RDS Proxy submodules.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Security](#security)
- [Submodules](#submodules)
- [Usage](#usage)
- [Module Structure](#module-structure)
- [Requirements](#requirements)
- [MCP Servers](#mcp-servers)

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

## Security

### Security Controls

Implements controls for FSBP, CIS, NIST 800-53/171, and PCI DSS v4.0:

- Encryption at rest with KMS customer-managed keys
- Automated encrypted backups with configurable retention
- Performance Insights and enhanced monitoring
- Multi-AZ high availability
- Deletion protection
- Security control overrides with audit justification

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

### Security Scan Suppressions

This module suppresses certain Checkov security checks that are either not applicable to example/demo code or represent optional features. The following checks are suppressed in `.checkov.yaml`:

**Module Source Versioning (CKV_TF_1, CKV_TF_2)**
- Suppressed because we use semantic version tags (`?ref=v1.0.0`) instead of commit hashes for better maintainability and readability
- Semantic versioning is a valid and widely-accepted versioning strategy for stable releases

**KMS IAM Policies (CKV_AWS_111, CKV_AWS_356, CKV_AWS_109)**
- Suppressed in example code where KMS modules use flexible IAM policies for demonstration purposes
- Production deployments should customize KMS policies based on specific security requirements and apply least privilege principles

**RDS Optional Features**
- **VPC Public Subnets (CKV_AWS_130)**: Public subnets are designed to auto-assign public IPs for resources that need internet access; this is intentional
- **Copy Tags to Snapshots (CKV_AWS_313)**: Optional feature; enable based on tagging requirements
- **IAM Authentication (CKV_AWS_162)**: Optional security feature that adds complexity; enable based on security requirements
- **Performance Insights (CKV_AWS_353)**: Optional monitoring feature that adds cost; enable based on monitoring requirements
- **Deletion Protection (CKV_AWS_293)**: Disabled in examples for easier cleanup; enable in production
- **Multi-AZ (CKV_AWS_157)**: Optional high availability feature that adds cost; enable based on availability requirements

## Submodules

| Submodule | Description |
|-----------|-------------|
| [aurora](modules/aurora/) | Aurora Serverless v2 PostgreSQL cluster |
| [proxy](modules/proxy/) | RDS Proxy for connection pooling |

## Usage

```hcl
module "aurora" {
  source = "github.com/islamelkadi/terraform-aws-rds"
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
