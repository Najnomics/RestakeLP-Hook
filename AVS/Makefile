# -----------------------------------------------------------------------------
# This Makefile is used for building the RestakeLP Hook AVS application.
#
# It contains targets for building the application, installing dependencies,
# building contracts, and building Docker containers.
#
# RestakeLP Hook AVS provides automated liquidity provision and restaking
# functionality for DeFi protocols through EigenLayer's restaking mechanism.
# -----------------------------------------------------------------------------

GO = $(shell which go)
OUT = ./bin

# Default target
.PHONY: all
all: build build-contracts

# Build the RestakeLP Hook AVS performer binary
.PHONY: build
build: deps
	@mkdir -p $(OUT) || true
	@echo "Building RestakeLP Hook AVS performer..."
	go build -o $(OUT)/restake-lp-performer ./cmd/main.go
	@echo "Build complete: $(OUT)/restake-lp-performer"

# Build smart contracts
.PHONY: build-contracts
build-contracts:
	@echo "Building RestakeLP Hook contracts..."
	cd .devkit/contracts && forge build
	@echo "Contract build complete"

# Install Go dependencies
.PHONY: deps
deps:
	@echo "Installing Go dependencies..."
	GOPRIVATE=github.com/Layr-Labs/* go mod tidy
	@echo "Dependencies installed"

# Build Docker container
.PHONY: build/container
build/container:
	@echo "Building RestakeLP Hook AVS Docker container..."
	./.hourglass/scripts/buildContainer.sh
	@echo "Docker container built"

# Run all tests
.PHONY: test
test: test-go test-forge
	@echo "All tests completed"

# Run Go tests
.PHONY: test-go
test-go:
	@echo "Running Go tests..."
	go test ./... -v -p 1
	@echo "Go tests completed"

# Run Forge tests
.PHONY: test-forge
test-forge:
	@echo "Running Forge tests..."
	cd .devkit/contracts && forge test
	@echo "Forge tests completed"

# Clean build artifacts
.PHONY: clean
clean:
	@echo "Cleaning build artifacts..."
	rm -rf $(OUT)
	cd .devkit/contracts && forge clean
	@echo "Clean complete"

# Format Go code
.PHONY: fmt
fmt:
	@echo "Formatting Go code..."
	go fmt ./...
	@echo "Formatting complete"

# Lint Go code
.PHONY: lint
lint:
	@echo "Linting Go code..."
	golangci-lint run
	@echo "Linting complete"

# Run the performer locally
.PHONY: run
run: build
	@echo "Starting RestakeLP Hook AVS performer..."
	./$(OUT)/restake-lp-performer

# Help target
.PHONY: help
help:
	@echo "RestakeLP Hook AVS Build System"
	@echo "==============================="
	@echo "Available targets:"
	@echo "  all           - Build everything (default)"
	@echo "  build         - Build the RestakeLP Hook AVS performer binary"
	@echo "  build-contracts - Build smart contracts"
	@echo "  deps          - Install Go dependencies"
	@echo "  build/container - Build Docker container"
	@echo "  test          - Run all tests"
	@echo "  test-go       - Run Go tests"
	@echo "  test-forge    - Run Forge tests"
	@echo "  clean         - Clean build artifacts"
	@echo "  fmt           - Format Go code"
	@echo "  lint          - Lint Go code"
	@echo "  run           - Run the performer locally"
	@echo "  help          - Show this help message"
