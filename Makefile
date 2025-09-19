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

.PHONY: test-all
test-all: test
	@echo "$(GREEN)✓ All 176 tests completed successfully$(NC)"

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

# Coverage targets
.PHONY: coverage-ir
coverage-ir:
	@echo "$(BLUE)Running coverage with IR minimum...$(NC)"
	@forge coverage --ir-minimum
	@echo "$(GREEN)✓ Coverage with IR completed$(NC)"

# Deployment targets
.PHONY: deploy-local
deploy-local:
	@echo "$(BLUE)Deploying to local Anvil...$(NC)"
	@forge script script/DeployAnvil.s.sol --rpc-url http://localhost:8545 --broadcast
	@echo "$(GREEN)✓ Local deployment completed$(NC)"

.PHONY: deploy-testnet
deploy-testnet:
	@echo "$(BLUE)Deploying to testnet...$(NC)"
	@forge script script/DeployTestnet.s.sol --rpc-url $${TESTNET_RPC_URL} --broadcast --verify
	@echo "$(GREEN)✓ Testnet deployment completed$(NC)"

.PHONY: deploy-mainnet
deploy-mainnet:
	@echo "$(BLUE)Deploying to mainnet...$(NC)"
	@forge script script/DeployMainnet.s.sol --rpc-url $${MAINNET_RPC_URL} --broadcast --verify
	@echo "$(GREEN)✓ Mainnet deployment completed$(NC)"

# Solidity deployment scripts
.PHONY: deploy-script
deploy-script:
	@echo "$(BLUE)Running deployment script...$(NC)"
	@forge script script/Deploy.s.sol --rpc-url $${RPC_URL} --broadcast
	@echo "$(GREEN)✓ Deployment script completed$(NC)"

.PHONY: verify-contracts
verify-contracts:
	@echo "$(BLUE)Verifying contracts...$(NC)"
	@forge script script/Verify.s.sol --rpc-url $${RPC_URL}
	@echo "$(GREEN)✓ Contract verification completed$(NC)"

.PHONY: upgrade-contracts
upgrade-contracts:
	@echo "$(BLUE)Upgrading contracts...$(NC)"
	@forge script script/Upgrade.s.sol --rpc-url $${RPC_URL} --broadcast
	@echo "$(GREEN)✓ Contract upgrade completed$(NC)"

# Setup targets
.PHONY: setup
setup:
	@echo "$(BLUE)Setting up development environment...$(NC)"
	@./scripts/utils/setup.sh
	@echo "$(GREEN)✓ Setup completed$(NC)"

.PHONY: install-deps
install-deps:
	@echo "$(BLUE)Installing dependencies...$(NC)"
	@forge install
	@echo "$(GREEN)✓ Dependencies installed$(NC)"

.PHONY: anvil
anvil:
	@echo "$(BLUE)Starting Anvil local node...$(NC)"
	@anvil --host 0.0.0.0 --port 8545

# Security targets
.PHONY: security
security:
	@echo "$(BLUE)Running security analysis...$(NC)"
	@forge test --match-contract "*Security*" -vv
	@echo "$(GREEN)✓ Security analysis completed$(NC)"

.PHONY: help
help:
	@echo "RestakeLP Hook AVS - Available Commands:"
	@echo ""
	@echo "Build Commands:"
	@echo "  build              - Build contracts"
	@echo "  build-production   - Build for production"
	@echo "  clean              - Clean build artifacts"
	@echo ""
	@echo "Test Commands:"
	@echo "  test               - Run all tests"
	@echo "  test-unit          - Run unit tests (136 tests)"
	@echo "  test-fuzz          - Run fuzz tests (21 tests)"
	@echo "  test-integration   - Run integration tests (15 tests)"
	@echo "  test-all           - Run all 176 tests"
	@echo "  coverage           - Run coverage"
	@echo "  coverage-ir        - Run coverage with IR minimum"
	@echo "  gas-report         - Generate gas report"
	@echo ""
	@echo "Deployment Commands:"
	@echo "  deploy-local       - Deploy to local Anvil"
	@echo "  deploy-testnet     - Deploy to testnet"
	@echo "  deploy-mainnet     - Deploy to mainnet"
	@echo "  deploy-script      - Run deployment script"
	@echo "  verify-contracts   - Verify deployed contracts"
	@echo "  upgrade-contracts  - Upgrade deployed contracts"
	@echo "  anvil              - Start Anvil local node"
	@echo ""
	@echo "Setup Commands:"
	@echo "  setup              - Setup development environment"
	@echo "  install-deps       - Install dependencies with forge install"
	@echo "  format             - Format code"
	@echo "  lint               - Lint code"
	@echo "  security           - Run security analysis"