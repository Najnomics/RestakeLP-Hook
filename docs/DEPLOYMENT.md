# RestakeLP Hook AVS - Deployment Guide

## Prerequisites

- **Node.js**: v18.0.0 or higher
- **Foundry**: Latest version
- **Go**: v1.23.6 or higher (for AVS components)
- **Git**: Latest version

## Environment Setup

### 1. Clone Repository
```bash
git clone https://github.com/RestakeLP/restake-lp-hook-avs.git
cd restake-lp-hook-avs
```

### 2. Install Dependencies
```bash
# Install Foundry
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Install project dependencies
forge install
```

### 3. Environment Configuration
Create a `.env` file in the root directory:

```bash
# Copy example environment file
cp .env.example .env
```

## Deployment Scripts

### Local Development (Anvil)

```bash
# Start local Anvil node
make anvil

# Deploy to local network
make deploy-local
```

### Testnet Deployment

```bash
# Deploy to Sepolia testnet
make deploy-testnet

# Verify contracts on Etherscan
make verify-testnet
```

### Mainnet Deployment

```bash
# Deploy to Ethereum mainnet
make deploy-mainnet

# Verify contracts on Etherscan
make verify-mainnet
```

## Contract Addresses

### Testnet (Sepolia)
- RestakeLPHook: `0x...`
- LiquidityManager: `0x...`
- YieldOptimizer: `0x...`

### Mainnet
- RestakeLPHook: `0x...`
- LiquidityManager: `0x...`
- YieldOptimizer: `0x...`

## Verification

### Etherscan Verification
```bash
# Verify all contracts
forge verify-contract --chain-id 1 --num-of-optimizations 200 --watch --etherscan-api-key $ETHERSCAN_API_KEY --constructor-args $(cast abi-encode "constructor(address)" $OWNER) $CONTRACT_ADDRESS src/contracts/RestakeLPHook.sol:RestakeLPHook
```

### Contract Verification
```bash
# Verify contract bytecode
make verify-bytecode

# Verify contract source
make verify-source
```

## Post-Deployment

### 1. Initialize Contracts
```bash
# Set up initial protocols
make init-protocols

# Set up initial tokens
make init-tokens

# Set up initial strategies
make init-strategies
```

### 2. Configure Parameters
```bash
# Set protocol fees
make set-fees

# Set yield strategies
make set-strategies

# Set risk parameters
make set-risk-params
```

### 3. Test Deployment
```bash
# Run integration tests
make test-integration

# Run end-to-end tests
make test-e2e

# Verify functionality
make verify-deployment
```

## Monitoring

### Health Checks
```bash
# Check contract health
make health-check

# Check gas usage
make gas-check

# Check performance
make performance-check
```

### Logs and Monitoring
```bash
# View deployment logs
make logs

# Monitor gas usage
make monitor-gas

# Check for errors
make check-errors
```

## Troubleshooting

### Common Issues

1. **Gas Estimation Failed**
   - Check RPC endpoint
   - Verify contract parameters
   - Check account balance

2. **Verification Failed**
   - Verify constructor arguments
   - Check optimization settings
   - Verify source code

3. **Transaction Failed**
   - Check gas limit
   - Verify account permissions
   - Check contract state

### Debug Commands
```bash
# Debug deployment
make debug-deployment

# Check transaction details
make check-tx

# Verify contract state
make check-state
```

## Security Considerations

- **Private Keys**: Store securely, never commit to repository
- **RPC Endpoints**: Use secure, reliable endpoints
- **Gas Limits**: Set appropriate gas limits for operations
- **Verification**: Always verify contracts after deployment
- **Monitoring**: Set up monitoring for deployed contracts
