# RestakeLP Hook AVS

## Overview

RestakeLP Hook is an EigenLayer AVS (Actively Validated Service) that provides automated liquidity provision and restaking functionality for DeFi protocols. This AVS enables operators to manage liquidity positions and automatically restake rewards to maximize yield while maintaining security through EigenLayer's restaking mechanism.

## Getting Started

After setting up this project, follow these steps to build and run your RestakeLP Hook AVS:

```bash
# Build your AVS Go code and contracts
devkit avs build

# Start the devnet (this will deploy contracts and start the Hourglass infrastructure). 
# `--skip-avs-run` will skip running your AVS Performer locally, allowing you to run it separately.
devkit avs devnet start [--skip-avs-run]

# If you ran devnet start with `--skip-avs-run`, you can now run your AVS Performer separately:
devkit avs run
```

## Architecture

### Go Code - `cmd/main.go`

The RestakeLP Performer implementation handles:

- `ValidateTask()` - Validates restaking and liquidity provision requests
- `HandleTask()` - Executes automated restaking and LP management operations
- `ProcessLiquidityProvision()` - Manages liquidity provision across supported protocols
- `ExecuteRestaking()` - Handles automatic restaking of rewards

### Smart Contracts

#### L1 Contracts (`contracts/src/l1-contracts/`)

- `RestakeLPRegistrar.sol` - L1 operator registration and management for RestakeLP operations
- `LiquidityManagerL1.sol` - L1 contract for managing cross-chain liquidity operations

#### L2 Contracts (`contracts/src/l2-contracts/`)

- `RestakeLPHook.sol` - Task lifecycle validation for restaking and LP operations
- `LiquidityManagerL2.sol` - L2 contract for executing liquidity provision and restaking tasks

## Features

- **Automated Restaking**: Automatically restake rewards from various DeFi protocols
- **Liquidity Management**: Intelligent liquidity provision across multiple DEXs
- **Yield Optimization**: Maximize returns through automated rebalancing
- **Security**: Leverages EigenLayer's restaking mechanism for enhanced security
- **Multi-Protocol Support**: Compatible with major DeFi protocols

## Configuration

The AVS supports various environments through configuration files in `specs/runtime/`:

- `devnet.yaml` - Development environment settings
- `testnet.yaml` - Testnet environment configuration  
- `mainnet.yaml` - Mainnet production settings

## Security Considerations

- This AVS handles significant value through liquidity provision and restaking
- All operations are validated through EigenLayer's consensus mechanism
- Operators must maintain proper security practices and monitoring
- Regular audits and security reviews are recommended

## ⚠️ Warning: This is Alpha, non-audited code ⚠️
RestakeLP Hook is in active development and is not yet audited. Use at your own risk.
