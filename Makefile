# HELP
# This will output the help for each task
# Thanks to https://marmelab.com/blog/2016/02/29/auto-documented-makefile.html
.PHONY: help test check-env clean

.DEFAULT_GOAL := help

# Variables
FUNCTIONS_DIR := $(shell realpath ./functions)
TEST_SCRIPTS := $(wildcard tests/test_*.sh)

help: ## Display this help message
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

test: check-env ## Run all tests
	@echo "Running tests..."
	@for script in $(TEST_SCRIPTS); do \
		echo "Running $$script..."; \
		FUNCTIONS_DIR=$(FUNCTIONS_DIR) /bin/bash $$script || true; \
	done
	@echo "Tests completed."

check-env: ## Verify required tools (bash, jq) are installed
	@echo "Checking environment..."
	@if ! command -v bash >/dev/null 2>&1; then \
		echo "Error: Bash is not installed or not in PATH."; \
		exit 1; \
	fi
	@if ! command -v jq >/dev/null 2>&1; then \
		echo "Error: jq is required but not installed. Please install jq."; \
		exit 1; \
	fi
	@echo "Environment checks passed."

clean: ## Clean up temporary files
	@echo "Cleaning up temporary files..."
	@find tests -type f -name '*.tmp' -delete
	@echo "Cleanup completed."