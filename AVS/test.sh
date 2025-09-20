#!/usr/bin/env bash

# RestakeLP Hook AVS Test Script
# This script runs comprehensive tests for the RestakeLP Hook AVS

set -e

echo "=========================================="
echo "RestakeLP Hook AVS Test Suite"
echo "=========================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Check if required tools are installed
check_dependencies() {
    print_status "Checking dependencies..."
    
    if ! command -v go &> /dev/null; then
        print_error "Go is not installed. Please install Go 1.23.6 or later."
        exit 1
    fi
    
    if ! command -v forge &> /dev/null; then
        print_error "Forge is not installed. Please install Foundry."
        exit 1
    fi
    
    print_status "All dependencies are installed."
}

# Run Go tests
run_go_tests() {
    print_status "Running Go tests..."
    if go test ./... -v -p 1; then
        print_status "Go tests passed ✓"
    else
        print_error "Go tests failed ✗"
        exit 1
    fi
}

# Run Forge tests
run_forge_tests() {
    print_status "Running Forge tests..."
    cd .devkit/contracts
    if forge test; then
        print_status "Forge tests passed ✓"
    else
        print_error "Forge tests failed ✗"
        exit 1
    fi
    cd ../..
}

# Build the application
build_application() {
    print_status "Building RestakeLP Hook AVS..."
    if make build; then
        print_status "Build successful ✓"
    else
        print_error "Build failed ✗"
        exit 1
    fi
}

# Run linting
run_linting() {
    print_status "Running code linting..."
    if command -v golangci-lint &> /dev/null; then
        if golangci-lint run; then
            print_status "Linting passed ✓"
        else
            print_warning "Linting issues found, but continuing..."
        fi
    else
        print_warning "golangci-lint not installed, skipping linting"
    fi
}

# Main test execution
main() {
    echo "Starting RestakeLP Hook AVS test suite..."
    echo ""
    
    check_dependencies
    echo ""
    
    run_linting
    echo ""
    
    build_application
    echo ""
    
    run_go_tests
    echo ""
    
    run_forge_tests
    echo ""
    
    print_status "=========================================="
    print_status "All tests completed successfully! ✓"
    print_status "RestakeLP Hook AVS is ready for deployment"
    print_status "=========================================="
}

# Run main function
main "$@"
