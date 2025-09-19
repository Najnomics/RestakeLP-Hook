#!/bin/bash

# RestakeLP Hook AVS - Environment Setup Script
# This script sets up the development environment

set -e

echo "🚀 Setting up RestakeLP Hook AVS development environment..."

# Check if Foundry is installed
if ! command -v forge &> /dev/null; then
    echo "📦 Installing Foundry..."
    curl -L https://foundry.paradigm.xyz | bash
    foundryup
else
    echo "✅ Foundry already installed"
fi

# Node.js is not required for Foundry projects
echo "✅ Node.js not required for Foundry projects"

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo "❌ Go is not installed. Please install Go v1.23.6+ first"
    exit 1
else
    echo "✅ Go already installed"
fi

# Install dependencies
echo "📦 Installing dependencies..."
forge install

# Create necessary directories
echo "📁 Creating directories..."
mkdir -p deployments
mkdir -p docs
mkdir -p scripts/deploy
mkdir -p scripts/utils

# Copy environment file if it doesn't exist
if [ ! -f .env ]; then
    echo "📄 Creating .env file from template..."
    cp .env.example .env
    echo "✅ .env file created. Please update it with your configuration."
else
    echo "✅ .env file already exists"
fi

# Make scripts executable
echo "🔧 Making scripts executable..."
chmod +x scripts/deploy/*.sh
chmod +x scripts/utils/*.sh

# Build contracts
echo "🔨 Building contracts..."
forge build

# Run tests
echo "🧪 Running tests..."
forge test

# Generate coverage report
echo "📊 Generating coverage report..."
forge coverage --ir-minimum

echo "✅ Environment setup completed!"
echo ""
echo "📋 Next steps:"
echo "   1. Update .env file with your configuration"
echo "   2. Start Anvil: anvil --host 0.0.0.0 --port 8545"
echo "   3. Deploy to Anvil: ./scripts/deploy/anvil.sh"
echo "   4. Deploy to testnet: ./scripts/deploy/testnet.sh"
echo "   5. Deploy to mainnet: ./scripts/deploy/mainnet.sh"
echo ""
echo "🔗 Useful commands:"
echo "   - Run tests: forge test"
echo "   - Run coverage: forge coverage --ir-minimum"
echo "   - Build contracts: forge build"
echo "   - Clean build: forge clean"
