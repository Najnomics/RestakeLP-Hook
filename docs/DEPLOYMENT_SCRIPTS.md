# RestakeLP Hook AVS - Deployment Scripts Guide

## Overview

The project includes both shell scripts and Solidity deployment scripts (.s.sol files) for comprehensive deployment management.

## Solidity Deployment Scripts (.s.sol)

### Available Scripts

1. **`script/Deploy.s.sol`** - Main deployment script
2. **`script/DeployAnvil.s.sol`** - Local Anvil deployment
3. **`script/DeployTestnet.s.sol`** - Sepolia testnet deployment
4. **`script/DeployMainnet.s.sol`** - Ethereum mainnet deployment
5. **`script/Verify.s.sol`** - Contract verification script
6. **`script/Upgrade.s.sol`** - Contract upgrade script

### Features

- **Environment-based configuration**: Uses environment variables for network-specific settings
- **Safety checks**: Includes balance verification and chain ID validation
- **Automatic initialization**: Sets up protocols, tokens, and strategies
- **Comprehensive logging**: Detailed deployment information and contract addresses
- **Error handling**: Proper error messages and validation

## Deployment Commands

### Using Make Commands

```bash
# Deploy to local Anvil
make deploy-local

# Deploy to testnet
make deploy-testnet

# Deploy to mainnet
make deploy-mainnet

# Run custom deployment script
make deploy-script

# Verify deployed contracts
make verify-contracts

# Upgrade deployed contracts
make upgrade-contracts
```

### Using Forge Scripts Directly

```bash
# Deploy to Anvil
forge script script/DeployAnvil.s.sol --rpc-url http://localhost:8545 --broadcast

# Deploy to testnet
forge script script/DeployTestnet.s.sol --rpc-url $TESTNET_RPC_URL --broadcast --verify

# Deploy to mainnet
forge script script/DeployMainnet.s.sol --rpc-url $MAINNET_RPC_URL --broadcast --verify

# Verify contracts
forge script script/Verify.s.sol --rpc-url $RPC_URL

# Upgrade contracts
forge script script/Upgrade.s.sol --rpc-url $RPC_URL --broadcast
```

## Environment Configuration

### Required Environment Variables

```bash
# RPC URLs
MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/YOUR_KEY
TESTNET_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/YOUR_KEY

# Private Keys
PRIVATE_KEY=your_private_key_here

# Contract Addresses (for verification/upgrade)
RESTAKE_HOOK_ADDRESS=0x...
LIQUIDITY_MANAGER_ADDRESS=0x...
YIELD_OPTIMIZER_ADDRESS=0x...
OWNER_ADDRESS=0x...

# API Keys
ETHERSCAN_API_KEY=your_etherscan_key
```

## Deployment Process

### 1. Local Development (Anvil)

```bash
# Start Anvil
make anvil

# Deploy contracts
make deploy-local
```

**Features:**
- Uses default Anvil account
- Funds contracts with test ETH
- Simplified setup for development
- No verification required

### 2. Testnet Deployment (Sepolia)

```bash
# Deploy to testnet
make deploy-testnet
```

**Features:**
- Uses testnet RPC URL
- Verifies contracts on Etherscan
- Conservative parameters
- Balance validation

### 3. Mainnet Deployment

```bash
# Deploy to mainnet
make deploy-mainnet
```

**Features:**
- Production configuration
- Safety checks and confirmations
- Full verification process
- Comprehensive strategy setup

## Contract Initialization

### Protocols Added

All deployment scripts automatically add these protocols:

- **Uniswap V3**: 1% fee
- **Balancer**: 1.5% fee
- **Aave**: 2% fee
- **Curve**: 0.5% fee
- **SushiSwap**: 3% fee

### Tokens Added

All deployment scripts automatically add these tokens:

- **DAI**: 18 decimals
- **USDC**: 6 decimals
- **USDT**: 6 decimals
- **WETH**: 18 decimals

### Strategies Created

**Mainnet/Testnet:**
- **balanced**: 40% Uniswap V3, 40% Balancer, 20% Aave
- **conservative**: 60% Aave, 40% Curve
- **aggressive**: 50% Uniswap V3, 50% SushiSwap

**Anvil:**
- **test-strategy**: 50% Uniswap V3, 50% Balancer

## Verification Process

### Automatic Verification

Testnet and mainnet deployments include automatic verification:

```bash
# Verify RestakeLPHook
forge verify-contract \
    --chain-id $CHAIN_ID \
    --num-of-optimizations 200 \
    --watch \
    --etherscan-api-key $ETHERSCAN_API_KEY \
    --constructor-args $(cast abi-encode "constructor(address)" $OWNER) \
    $RESTAKE_HOOK_ADDRESS \
    src/contracts/RestakeLPHook.sol:RestakeLPHook
```

### Manual Verification

```bash
# Verify all contracts
make verify-contracts

# Or use the verification script
forge script script/Verify.s.sol --rpc-url $RPC_URL
```

## Upgrade Process

### Contract Upgrades

```bash
# Upgrade contracts
make upgrade-contracts

# Or use the upgrade script
forge script script/Upgrade.s.sol --rpc-url $RPC_URL --broadcast
```

**Features:**
- Parameter updates
- Contract state verification
- Safety checks
- Rollback capability

## Deployment Artifacts

### Generated Files

- **`broadcast/`**: Deployment transactions and receipts
- **`deployments/`**: Contract addresses and deployment info
- **`out/`**: Compiled contracts and artifacts

### Deployment JSON

Each deployment creates a JSON file with contract addresses:

```json
{
  "chainId": 1,
  "network": "mainnet",
  "deployments": {
    "RestakeLPHook": "0x...",
    "LiquidityManager": "0x...",
    "YieldOptimizer": "0x..."
  },
  "deployedAt": "2024-01-01T00:00:00Z"
}
```

## Troubleshooting

### Common Issues

1. **Insufficient Balance**
   - Ensure account has enough ETH for deployment
   - Check gas price and limits

2. **RPC Connection Issues**
   - Verify RPC URL is correct
   - Check network connectivity

3. **Verification Failures**
   - Ensure constructor arguments are correct
   - Check optimization settings

4. **Contract Initialization Failures**
   - Verify protocol addresses are correct
   - Check token addresses and decimals

### Debug Commands

```bash
# Check deployment status
forge script script/Verify.s.sol --rpc-url $RPC_URL

# View deployment logs
forge script script/Deploy.s.sol --rpc-url $RPC_URL --broadcast -vvvv

# Check contract state
cast call $CONTRACT_ADDRESS "owner()" --rpc-url $RPC_URL
```

## Security Considerations

### Pre-deployment Checks

- [ ] Verify all environment variables
- [ ] Test on testnet first
- [ ] Review contract parameters
- [ ] Check gas estimates
- [ ] Verify constructor arguments

### Post-deployment Checks

- [ ] Verify contracts on Etherscan
- [ ] Test all contract functions
- [ ] Check access controls
- [ ] Verify initialization
- [ ] Monitor for issues

## Best Practices

1. **Always test on testnet first**
2. **Use environment variables for sensitive data**
3. **Keep deployment records**
4. **Verify contracts immediately after deployment**
5. **Monitor deployed contracts**
6. **Have rollback plans ready**

## Support

For deployment issues or questions:

- **Documentation**: Check this guide and other docs
- **Issues**: Report via GitHub issues
- **Discord**: [discord.gg/restakelp](https://discord.gg/restakelp)
- **Email**: support@restakelp.xyz
