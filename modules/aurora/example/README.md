# Basic Aurora PostgreSQL Example

This example creates an Aurora Serverless v2 PostgreSQL cluster using fictitious subnet, security group, and KMS key IDs.

## Usage

```bash
terraform init
terraform plan -var-file=params/input.tfvars
terraform apply -var-file=params/input.tfvars
```

## What This Example Creates

- Aurora Serverless v2 PostgreSQL cluster with configurable scaling
- Multi-instance deployment for high availability
- Performance Insights and enhanced monitoring
- CloudWatch Logs export

## Clean Up

```bash
terraform destroy -var-file=params/input.tfvars
```
