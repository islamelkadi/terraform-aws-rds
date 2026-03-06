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
