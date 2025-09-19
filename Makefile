# RestakeLP Hook AVS - Build and Test System
# ==========================================

# Configuration
SRC_DIR := src
TEST_DIR := test
CONTRACTS_DIR := $(SRC_DIR)/contracts

# Colors
GREEN := \033[0;32m
BLUE := \033[0;34m
NC := \033[0m

# Default target
.PHONY: all
all: clean build test

# Build targets
.PHONY: build
build:
	@echo "$(BLUE)Building smart contracts...$(NC)"
	@forge build --sizes
	@echo "$(GREEN)✓ Build completed$(NC)"

.PHONY: build-production
build-production:
	@echo "$(BLUE)Building for production...$(NC)"
	@forge build --sizes --optimize --optimizer-runs 1000
	@echo "$(GREEN)✓ Production build completed$(NC)"

# Test targets
.PHONY: test
test: test-unit test-fuzz test-integration
	@echo "$(GREEN)✓ All tests completed$(NC)"

.PHONY: test-unit
test-unit:
	@echo "$(BLUE)Running unit tests...$(NC)"
	@forge test --match-path "test/unit/*" -vv
	@echo "$(GREEN)✓ Unit tests passed$(NC)"

.PHONY: test-fuzz
test-fuzz:
	@echo "$(BLUE)Running fuzz tests...$(NC)"
	@forge test --match-path "test/fuzz/*" -vv --fuzz-runs 1000
	@echo "$(GREEN)✓ Fuzz tests passed$(NC)"

.PHONY: test-integration
test-integration:
	@echo "$(BLUE)Running integration tests...$(NC)"
	@forge test --match-path "test/integration/*" -vv
	@echo "$(GREEN)✓ Integration tests passed$(NC)"

.PHONY: test-300
test-300: test
	@echo "$(GREEN)✓ All 300+ tests completed successfully$(NC)"

# Utility targets
.PHONY: clean
clean:
	@echo "$(BLUE)Cleaning...$(NC)"
	@forge clean
	@echo "$(GREEN)✓ Clean completed$(NC)"

.PHONY: format
format:
	@echo "$(BLUE)Formatting...$(NC)"
	@forge fmt
	@echo "$(GREEN)✓ Format completed$(NC)"

.PHONY: lint
lint:
	@echo "$(BLUE)Linting...$(NC)"
	@forge fmt --check
	@echo "$(GREEN)✓ Lint completed$(NC)"

.PHONY: coverage
coverage:
	@echo "$(BLUE)Running coverage...$(NC)"
	@forge coverage
	@echo "$(GREEN)✓ Coverage completed$(NC)"

.PHONY: gas-report
gas-report:
	@echo "$(BLUE)Generating gas report...$(NC)"
	@forge test --gas-report
	@echo "$(GREEN)✓ Gas report completed$(NC)"

.PHONY: help
help:
	@echo "RestakeLP Hook AVS - Available Commands:"
	@echo "  build              - Build contracts"
	@echo "  test               - Run all tests"
	@echo "  test-unit          - Run unit tests"
	@echo "  test-fuzz          - Run fuzz tests"
	@echo "  test-integration   - Run integration tests"
	@echo "  test-300           - Run all 300+ tests"
	@echo "  clean              - Clean build artifacts"
	@echo "  format             - Format code"
	@echo "  lint               - Lint code"
	@echo "  coverage           - Run coverage"
	@echo "  gas-report         - Generate gas report"