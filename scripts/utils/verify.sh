#!/bin/bash

# RestakeLP Hook AVS - Contract Verification Script
# This script verifies deployed contracts on Etherscan

set -e

# Function to display usage
usage() {
    echo "Usage: $0 [network] [contract_address]"
    echo ""
    echo "Networks:"
    echo "  anvil     - Local Anvil network"
    echo "  testnet   - Ethereum Sepolia testnet"
    echo "  mainnet   - Ethereum mainnet"
    echo ""
    echo "Examples:"
    echo "  $0 testnet 0x1234567890123456789012345678901234567890"
    echo "  $0 mainnet 0x1234567890123456789012345678901234567890"
    exit 1
}

# Check arguments
if [ $# -ne 2 ]; then
    usage
fi

NETWORK=$1
CONTRACT_ADDRESS=$2

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '#' | awk '/=/ {print $1}')
fi

# Set network-specific variables
case $NETWORK in
    "anvil")
        RPC_URL=${ANVIL_RPC_URL:-"http://localhost:8545"}
        CHAIN_ID=31337
        ETHERSCAN_API_KEY=""
        ;;
    "testnet")
        RPC_URL=$TESTNET_RPC_URL
        CHAIN_ID=11155111
        ETHERSCAN_API_KEY=$ETHERSCAN_API_KEY
        ;;
    "mainnet")
        RPC_URL=$MAINNET_RPC_URL
        CHAIN_ID=1
        ETHERSCAN_API_KEY=$ETHERSCAN_API_KEY
        ;;
    *)
        echo "❌ Invalid network: $NETWORK"
        usage
        ;;
esac

# Check required variables
if [ -z "$RPC_URL" ]; then
    echo "❌ RPC URL not set for network: $NETWORK"
    exit 1
fi

if [ "$NETWORK" != "anvil" ] && [ -z "$ETHERSCAN_API_KEY" ]; then
    echo "❌ ETHERSCAN_API_KEY not set for network: $NETWORK"
    exit 1
fi

echo "🔍 Verifying contract on $NETWORK..."
echo "   Contract Address: $CONTRACT_ADDRESS"
echo "   RPC URL: $RPC_URL"
echo "   Chain ID: $CHAIN_ID"

# Determine contract type based on address
# This is a simplified approach - in practice, you'd want to check the actual contract
if [ -f "deployments/$NETWORK.json" ]; then
    RESTAKE_HOOK=$(jq -r '.deployments.RestakeLPHook' deployments/$NETWORK.json)
    LIQUIDITY_MANAGER=$(jq -r '.deployments.LiquidityManager' deployments/$NETWORK.json)
    YIELD_OPTIMIZER=$(jq -r '.deployments.YieldOptimizer' deployments/$NETWORK.json)
    
    if [ "$CONTRACT_ADDRESS" = "$RESTAKE_HOOK" ]; then
        CONTRACT_NAME="RestakeLPHook"
        CONTRACT_PATH="src/contracts/RestakeLPHook.sol:RestakeLPHook"
    elif [ "$CONTRACT_ADDRESS" = "$LIQUIDITY_MANAGER" ]; then
        CONTRACT_NAME="LiquidityManager"
        CONTRACT_PATH="src/contracts/LiquidityManager.sol:LiquidityManager"
    elif [ "$CONTRACT_ADDRESS" = "$YIELD_OPTIMIZER" ]; then
        CONTRACT_NAME="YieldOptimizer"
        CONTRACT_PATH="src/contracts/YieldOptimizer.sol:YieldOptimizer"
    else
        echo "❌ Contract address not found in deployments/$NETWORK.json"
        echo "   Available contracts:"
        echo "   - RestakeLPHook: $RESTAKE_HOOK"
        echo "   - LiquidityManager: $LIQUIDITY_MANAGER"
        echo "   - YieldOptimizer: $YIELD_OPTIMIZER"
        exit 1
    fi
else
    echo "❌ Deployment file not found: deployments/$NETWORK.json"
    exit 1
fi

echo "   Contract Name: $CONTRACT_NAME"
echo "   Contract Path: $CONTRACT_PATH"

# Skip verification for Anvil
if [ "$NETWORK" = "anvil" ]; then
    echo "ℹ️  Skipping verification for Anvil network"
    echo "✅ Contract verification skipped (Anvil)"
    exit 0
fi

# Verify contract
echo "   Verifying contract on Etherscan..."

forge verify-contract \
    --chain-id $CHAIN_ID \
    --num-of-optimizations 200 \
    --watch \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --constructor-args $(cast abi-encode "constructor(address)" $DEPLOYER_PRIVATE_KEY) \
    $CONTRACT_ADDRESS \
    $CONTRACT_PATH

echo "✅ Contract verification completed!"
echo "🔗 View on Etherscan: https://etherscan.io/address/$CONTRACT_ADDRESS"
