# Terraform Module: Rds
# This makefile provides common Terraform operations for the Rds module

.PHONY: help bootstrap fmt lint security docs submodules clean all

# Default target
help:
	@echo "Available targets:"
	@echo "  bootstrap  - Install required tools (macOS only)"
	@echo "  fmt        - Format Terraform files"
	@echo "  lint       - Run tflint on configuration"
	@echo "  security   - Run security scan with checkov"
	@echo "  docs       - Generate module documentation"
	@echo "  submodules - Run all checks on submodules"
	@echo "  clean      - Remove Terraform state and cache files"
	@echo "  all        - Run fmt, lint, security, docs, submodules"

# Install required tools (macOS)
bootstrap:
	@echo "Bootstrapping development environment..."
	@which brew > /dev/null || (echo "Error: Homebrew is required. Install from https://brew.sh" && exit 1)
	@echo "Installing tfenv..."
	@brew list tfenv > /dev/null 2>&1 || brew install tfenv
	@echo "Installing Terraform via tfenv..."
	@tfenv install latest && tfenv use latest
	@echo "Installing tflint..."
	@brew list tflint > /dev/null 2>&1 || brew install tflint
	@echo "Installing terraform-docs..."
	@brew list terraform-docs > /dev/null 2>&1 || brew install terraform-docs
	@echo "Installing checkov..."
	@pip install --quiet --upgrade checkov
	@echo "Installing pre-commit..."
	@pip install --quiet --upgrade pre-commit
	@echo "Setting up pre-commit hooks..."
	@pre-commit install
	@echo "Bootstrap complete!"

# Format Terraform files
fmt:
	@echo "Formatting Terraform files..."
	terraform fmt -recursive

# Run tflint
lint:
	@echo "Running tflint..."
	tflint --init
	tflint

# Run security scan
security:
	@echo "Running security scan with checkov..."
	checkov -d . --config-file .checkov.yaml

# Generate documentation
docs:
	@echo "Generating module documentation..."
	terraform-docs markdown table --output-file README.md --output-mode inject .

# Run checks on submodules
submodules:
	@echo "Running checks on submodules..."
	@for dir in modules/*/; do \
		if [ -f "$$dir/makefile" ]; then \
			echo "Processing $$dir..."; \
			$(MAKE) -C $$dir all; \
		fi; \
	done

# Clean Terraform files
clean:
	@echo "Cleaning Terraform files..."
	rm -rf .terraform .terraform.lock.hcl
	@for dir in modules/*/; do \
		if [ -f "$$dir/makefile" ]; then \
			$(MAKE) -C $$dir clean; \
		fi; \
	done

# Run all checks
all: fmt lint security docs submodules
	@echo "All checks completed successfully!"
