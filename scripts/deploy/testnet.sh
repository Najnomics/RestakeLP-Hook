#!/bin/bash

# RestakeLP Hook AVS - Testnet Deployment Script
# This script deploys all contracts to Ethereum Sepolia testnet

set -e

echo "🚀 Starting RestakeLP Hook AVS deployment to Sepolia testnet..."

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '#' | awk '/=/ {print $1}')
fi

# Check required environment variables
if [ -z "$TESTNET_RPC_URL" ]; then
    echo "❌ TESTNET_RPC_URL not set in .env file"
    exit 1
fi

if [ -z "$DEPLOYER_PRIVATE_KEY" ]; then
    echo "❌ DEPLOYER_PRIVATE_KEY not set in .env file"
    exit 1
fi

if [ -z "$ETHERSCAN_API_KEY" ]; then
    echo "❌ ETHERSCAN_API_KEY not set in .env file"
    exit 1
fi

# Set default values
export RPC_URL=$TESTNET_RPC_URL
export CHAIN_ID=11155111
export ETHERSCAN_API_KEY=$ETHERSCAN_API_KEY

echo "📋 Deployment Configuration:"
echo "   RPC URL: $RPC_URL"
echo "   Chain ID: $CHAIN_ID"
echo "   Private Key: ${DEPLOYER_PRIVATE_KEY:0:10}..."

# Check account balance
BALANCE=$(cast balance $DEPLOYER_PRIVATE_KEY --rpc-url $RPC_URL)
echo "   Account Balance: $(cast to-unit $BALANCE ether) ETH"

if [ $(cast to-unit $BALANCE ether | cut -d. -f1) -lt 1 ]; then
    echo "❌ Insufficient balance. Please fund your account with at least 1 ETH"
    exit 1
fi

# Deploy contracts
echo "📦 Deploying contracts..."

# Deploy RestakeLPHook
echo "   Deploying RestakeLPHook..."
RESTAKE_HOOK_ADDRESS=$(forge create \
    --rpc-url $RPC_URL \
    --private-key $DEPLOYER_PRIVATE_KEY \
    --constructor-args $DEPLOYER_PRIVATE_KEY \
    src/contracts/RestakeLPHook.sol:RestakeLPHook \
    | grep "Deployed to:" | awk '{print $3}')

echo "   ✅ RestakeLPHook deployed to: $RESTAKE_HOOK_ADDRESS"

# Deploy LiquidityManager
echo "   Deploying LiquidityManager..."
LIQUIDITY_MANAGER_ADDRESS=$(forge create \
    --rpc-url $RPC_URL \
    --private-key $DEPLOYER_PRIVATE_KEY \
    --constructor-args $DEPLOYER_PRIVATE_KEY \
    src/contracts/LiquidityManager.sol:LiquidityManager \
    | grep "Deployed to:" | awk '{print $3}')

echo "   ✅ LiquidityManager deployed to: $LIQUIDITY_MANAGER_ADDRESS"

# Deploy YieldOptimizer
echo "   Deploying YieldOptimizer..."
YIELD_OPTIMIZER_ADDRESS=$(forge create \
    --rpc-url $RPC_URL \
    --private-key $DEPLOYER_PRIVATE_KEY \
    --constructor-args $DEPLOYER_PRIVATE_KEY \
    src/contracts/YieldOptimizer.sol:YieldOptimizer \
    | grep "Deployed to:" | awk '{print $3}')

echo "   ✅ YieldOptimizer deployed to: $YIELD_OPTIMIZER_ADDRESS"

# Save deployment addresses
echo "💾 Saving deployment addresses..."
mkdir -p deployments
cat > deployments/sepolia.json << EOF
{
  "chainId": $CHAIN_ID,
  "network": "sepolia",
  "deployments": {
    "RestakeLPHook": "$RESTAKE_HOOK_ADDRESS",
    "LiquidityManager": "$LIQUIDITY_MANAGER_ADDRESS",
    "YieldOptimizer": "$YIELD_OPTIMIZER_ADDRESS"
  },
  "deployedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

# Verify contracts on Etherscan
echo "🔍 Verifying contracts on Etherscan..."

echo "   Verifying RestakeLPHook..."
forge verify-contract \
    --chain-id $CHAIN_ID \
    --num-of-optimizations 200 \
    --watch \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --constructor-args $(cast abi-encode "constructor(address)" $DEPLOYER_PRIVATE_KEY) \
    $RESTAKE_HOOK_ADDRESS \
    src/contracts/RestakeLPHook.sol:RestakeLPHook

echo "   Verifying LiquidityManager..."
forge verify-contract \
    --chain-id $CHAIN_ID \
    --num-of-optimizations 200 \
    --watch \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --constructor-args $(cast abi-encode "constructor(address)" $DEPLOYER_PRIVATE_KEY) \
    $LIQUIDITY_MANAGER_ADDRESS \
    src/contracts/LiquidityManager.sol:LiquidityManager

echo "   Verifying YieldOptimizer..."
forge verify-contract \
    --chain-id $CHAIN_ID \
    --num-of-optimizations 200 \
    --watch \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --constructor-args $(cast abi-encode "constructor(address)" $DEPLOYER_PRIVATE_KEY) \
    $YIELD_OPTIMIZER_ADDRESS \
    src/contracts/YieldOptimizer.sol:YieldOptimizer

# Initialize contracts
echo "🔧 Initializing contracts..."

# Add initial protocols
echo "   Adding initial protocols..."
cast send $RESTAKE_HOOK_ADDRESS \
    --rpc-url $RPC_URL \
    --private-key $DEPLOYER_PRIVATE_KEY \
    "addProtocol(address,string,address,uint256)" \
    0x1F98431c8aD98523631AE4a59f267346ea31F984 \
    "Uniswap V3" \
    0x0000000000000000000000000000000000000000 \
    100

cast send $RESTAKE_HOOK_ADDRESS \
    --rpc-url $RPC_URL \
    --private-key $DEPLOYER_PRIVATE_KEY \
    "addProtocol(address,string,address,uint256)" \
    0xBA12222222228d8Ba445958a75a0704d566BF2C8 \
    "Balancer" \
    0x0000000000000000000000000000000000000000 \
    150

# Add initial tokens
echo "   Adding initial tokens..."
cast send $RESTAKE_HOOK_ADDRESS \
    --rpc-url $RPC_URL \
    --private-key $DEPLOYER_PRIVATE_KEY \
    "addToken(address,string,string,uint8)" \
    0x6B175474E89094C44Da98b954EedeAC495271d0F \
    "DAI" \
    "Dai Stablecoin" \
    18

cast send $RESTAKE_HOOK_ADDRESS \
    --rpc-url $RPC_URL \
    --private-key $DEPLOYER_PRIVATE_KEY \
    "addToken(address,string,string,uint8)" \
    0xA0b86a33E6441b8C4C8C0e4B8b8C8C0e4B8b8C8C \
    "USDC" \
    "USD Coin" \
    6

echo "✅ Deployment completed successfully!"
echo ""
echo "📋 Contract Addresses:"
echo "   RestakeLPHook: $RESTAKE_HOOK_ADDRESS"
echo "   LiquidityManager: $LIQUIDITY_MANAGER_ADDRESS"
echo "   YieldOptimizer: $YIELD_OPTIMIZER_ADDRESS"
echo ""
echo "🔗 Etherscan: https://sepolia.etherscan.io/address/$RESTAKE_HOOK_ADDRESS"
echo "📄 Deployment saved to: deployments/sepolia.json"
