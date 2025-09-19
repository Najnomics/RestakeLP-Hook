#!/bin/bash

# RestakeLP Hook AVS - Local Anvil Deployment Script
# This script deploys all contracts to a local Anvil node

set -e

echo "🚀 Starting RestakeLP Hook AVS deployment to Anvil..."

# Check if Anvil is running
if ! curl -s http://localhost:8545 > /dev/null; then
    echo "❌ Anvil is not running. Please start Anvil first:"
    echo "   anvil --host 0.0.0.0 --port 8545"
    exit 1
fi

# Load environment variables
if [ -f .env ]; then
    export $(cat .env | grep -v '#' | awk '/=/ {print $1}')
fi

# Set default values if not provided
export PRIVATE_KEY=${PRIVATE_KEY:-"0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80"}
export RPC_URL=${ANVIL_RPC_URL:-"http://localhost:8545"}
export CHAIN_ID=${CHAIN_ID:-"31337"}

echo "📋 Deployment Configuration:"
echo "   RPC URL: $RPC_URL"
echo "   Chain ID: $CHAIN_ID"
echo "   Private Key: ${PRIVATE_KEY:0:10}..."

# Deploy contracts
echo "📦 Deploying contracts..."

# Deploy RestakeLPHook
echo "   Deploying RestakeLPHook..."
RESTAKE_HOOK_ADDRESS=$(forge create \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --constructor-args $PRIVATE_KEY \
    src/contracts/RestakeLPHook.sol:RestakeLPHook \
    | grep "Deployed to:" | awk '{print $3}')

echo "   ✅ RestakeLPHook deployed to: $RESTAKE_HOOK_ADDRESS"

# Deploy LiquidityManager
echo "   Deploying LiquidityManager..."
LIQUIDITY_MANAGER_ADDRESS=$(forge create \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --constructor-args $PRIVATE_KEY \
    src/contracts/LiquidityManager.sol:LiquidityManager \
    | grep "Deployed to:" | awk '{print $3}')

echo "   ✅ LiquidityManager deployed to: $LIQUIDITY_MANAGER_ADDRESS"

# Deploy YieldOptimizer
echo "   Deploying YieldOptimizer..."
YIELD_OPTIMIZER_ADDRESS=$(forge create \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    --constructor-args $PRIVATE_KEY \
    src/contracts/YieldOptimizer.sol:YieldOptimizer \
    | grep "Deployed to:" | awk '{print $3}')

echo "   ✅ YieldOptimizer deployed to: $YIELD_OPTIMIZER_ADDRESS"

# Save deployment addresses
echo "💾 Saving deployment addresses..."
cat > deployments/anvil.json << EOF
{
  "chainId": $CHAIN_ID,
  "network": "anvil",
  "deployments": {
    "RestakeLPHook": "$RESTAKE_HOOK_ADDRESS",
    "LiquidityManager": "$LIQUIDITY_MANAGER_ADDRESS",
    "YieldOptimizer": "$YIELD_OPTIMIZER_ADDRESS"
  },
  "deployedAt": "$(date -u +%Y-%m-%dT%H:%M:%SZ)"
}
EOF

# Initialize contracts
echo "🔧 Initializing contracts..."

# Add initial protocols
echo "   Adding initial protocols..."
cast send $RESTAKE_HOOK_ADDRESS \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    "addProtocol(address,string,address,uint256)" \
    0x1F98431c8aD98523631AE4a59f267346ea31F984 \
    "Uniswap V3" \
    0x0000000000000000000000000000000000000000 \
    100

cast send $RESTAKE_HOOK_ADDRESS \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    "addProtocol(address,string,address,uint256)" \
    0xBA12222222228d8Ba445958a75a0704d566BF2C8 \
    "Balancer" \
    0x0000000000000000000000000000000000000000 \
    150

# Add initial tokens
echo "   Adding initial tokens..."
cast send $RESTAKE_HOOK_ADDRESS \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    "addToken(address,string,string,uint8)" \
    0xA0b86a33E6441b8C4C8C0e4B8b8C8C0e4B8b8C8C \
    "USDC" \
    "USD Coin" \
    6

cast send $RESTAKE_HOOK_ADDRESS \
    --rpc-url $RPC_URL \
    --private-key $PRIVATE_KEY \
    "addToken(address,string,string,uint8)" \
    0xB0b86a33E6441b8C4C8C0e4B8b8C8C0e4B8b8C8C \
    "USDT" \
    "Tether USD" \
    6

# Run tests
echo "🧪 Running tests..."
forge test --rpc-url $RPC_URL --match-contract "*Integration*" -vv

echo "✅ Deployment completed successfully!"
echo ""
echo "📋 Contract Addresses:"
echo "   RestakeLPHook: $RESTAKE_HOOK_ADDRESS"
echo "   LiquidityManager: $LIQUIDITY_MANAGER_ADDRESS"
echo "   YieldOptimizer: $YIELD_OPTIMIZER_ADDRESS"
echo ""
echo "🔗 Anvil Explorer: http://localhost:8545"
echo "📄 Deployment saved to: deployments/anvil.json"
