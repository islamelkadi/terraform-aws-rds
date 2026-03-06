# Terraform Submodule: Proxy
# This makefile provides common Terraform operations for the Proxy submodule

.PHONY: help init validate fmt lint security docs clean all

# Default target
help:
	@echo "Available targets:"
	@echo "  init      - Initialize Terraform (download providers)"
	@echo "  validate  - Validate Terraform configuration"
	@echo "  fmt       - Format Terraform files"
	@echo "  lint      - Run tflint on configuration"
	@echo "  security  - Run security scan with checkov"
	@echo "  docs      - Generate submodule documentation"
	@echo "  clean     - Remove Terraform state and cache files"
	@echo "  all       - Run init, fmt, validate, lint, security, docs"

# Initialize Terraform
init:
	@echo "Initializing Terraform..."
	terraform init -upgrade

# Validate configuration
validate: init
	@echo "Validating Terraform configuration..."
	terraform validate

# Format Terraform files
fmt:
	@echo "Formatting Terraform files..."
	terraform fmt -recursive

# Run tflint
lint: init
	@echo "Running tflint..."
	tflint --init
	tflint

# Run security scan
security:
	@echo "Running security scan with checkov..."
	checkov -d . --framework terraform

# Generate documentation
docs:
	@echo "Generating submodule documentation..."
	terraform-docs markdown table --output-file README.md --output-mode inject .

# Clean Terraform files
clean:
	@echo "Cleaning Terraform files..."
	rm -rf .terraform .terraform.lock.hcl

# Run all checks
all: init fmt validate lint security docs
	@echo "All checks completed successfully!"
