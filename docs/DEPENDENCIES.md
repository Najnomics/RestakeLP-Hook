# RestakeLP Hook AVS - Dependencies

## Overview

This project uses Foundry for development and testing, with dependencies managed through `forge install`.

## Core Dependencies

### forge-std
- **Purpose**: Foundry standard library for testing and scripting
- **Usage**: Used in all test files and deployment scripts
- **Installation**: `forge install foundry-rs/forge-std`
- **Files**: `lib/forge-std/`

### openzeppelin-contracts
- **Purpose**: Secure contract libraries and standards
- **Usage**: 
  - `Ownable` - Access control
  - `ReentrancyGuard` - Reentrancy protection
  - `Pausable` - Emergency pause functionality
  - `SafeERC20` - Safe ERC20 operations
  - `Math` - Mathematical utilities
- **Installation**: `forge install OpenZeppelin/openzeppelin-contracts`
- **Files**: `lib/openzeppelin-contracts/`

### eigenlayer-middleware
- **Purpose**: EigenLayer AVS framework and middleware
- **Usage**: EigenLayer integration for restaking
- **Installation**: `forge install Layr-Labs/eigenlayer-middleware`
- **Files**: `lib/eigenlayer-middleware/`

## Additional Dependencies

### chainlink-brownie-contracts
- **Purpose**: Chainlink oracle contracts
- **Usage**: Price feeds and external data
- **Installation**: `forge install smartcontractkit/chainlink-brownie-contracts`
- **Files**: `lib/chainlink-brownie-contracts/`

### contracts (Across Protocol)
- **Purpose**: Across Protocol bridge contracts
- **Usage**: Cross-chain bridge functionality
- **Installation**: `forge install across-protocol/contracts`
- **Files**: `lib/contracts/`

### v4-core (Uniswap V4)
- **Purpose**: Uniswap V4 core contracts
- **Usage**: AMM functionality
- **Installation**: `forge install Uniswap/v4-core`
- **Files**: `lib/v4-core/`

### v4-periphery (Uniswap V4)
- **Purpose**: Uniswap V4 periphery contracts
- **Usage**: AMM periphery functionality
- **Installation**: `forge install Uniswap/v4-periphery`
- **Files**: `lib/v4-periphery/`

## Installation

### Install All Dependencies
```bash
forge install
```

### Install Individual Dependencies
```bash
# Core dependencies
forge install foundry-rs/forge-std
forge install OpenZeppelin/openzeppelin-contracts
forge install Layr-Labs/eigenlayer-middleware

# Additional dependencies
forge install smartcontractkit/chainlink-brownie-contracts
forge install across-protocol/contracts
forge install Uniswap/v4-core
forge install Uniswap/v4-periphery
```

### Update Dependencies
```bash
# Update all dependencies
forge update

# Update specific dependency
forge update lib/openzeppelin-contracts
```

## Usage in Contracts

### Import Statements
```solidity
// Foundry testing
import {Test} from "forge-std/Test.sol";

// OpenZeppelin contracts
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

// Project contracts
import {RestakeLPHook} from "../src/contracts/RestakeLPHook.sol";
import {LiquidityManager} from "../src/contracts/LiquidityManager.sol";
import {YieldOptimizer} from "../src/contracts/YieldOptimizer.sol";
```

## Dependency Management

### .gitmodules
The project uses Git submodules for dependency management. The `.gitmodules` file contains:

```ini
[submodule "lib/forge-std"]
	path = lib/forge-std
	url = https://github.com/foundry-rs/forge-std

[submodule "lib/openzeppelin-contracts"]
	path = lib/openzeppelin-contracts
	url = https://github.com/OpenZeppelin/openzeppelin-contracts

[submodule "lib/eigenlayer-middleware"]
	path = lib/eigenlayer-middleware
	url = https://github.com/Layr-Labs/eigenlayer-middleware

[submodule "lib/chainlink-brownie-contracts"]
	path = lib/chainlink-brownie-contracts
	url = https://github.com/smartcontractkit/chainlink-brownie-contracts

[submodule "lib/contracts"]
	path = lib/contracts
	url = https://github.com/across-protocol/contracts

[submodule "lib/v4-core"]
	path = lib/v4-core
	url = https://github.com/Uniswap/v4-core

[submodule "lib/v4-periphery"]
	path = lib/v4-periphery
	url = https://github.com/Uniswap/v4-periphery
```

### foundry.toml
The project configuration includes remappings for clean imports:

```toml
[profile.default]
src = "src"
out = "out"
libs = ["lib"]
optimizer = true
optimizer_runs = 200
via_ir = true
fuzz_runs = 256

[profile.production]
optimizer = true
optimizer_runs = 1000
via_ir = true
```

## Troubleshooting

### Common Issues

1. **Missing Dependencies**
   ```bash
   # Reinstall all dependencies
   forge install
   ```

2. **Outdated Dependencies**
   ```bash
   # Update all dependencies
   forge update
   ```

3. **Import Errors**
   - Check that dependencies are installed
   - Verify import paths are correct
   - Ensure foundry.toml is configured properly

4. **Version Conflicts**
   - Check dependency versions
   - Update conflicting dependencies
   - Use specific commit hashes if needed

### Verification

```bash
# Check installed dependencies
ls lib/

# Verify imports work
forge build

# Run tests to verify functionality
forge test
```

## Security Considerations

- **Audit Dependencies**: Review dependency code for security issues
- **Pin Versions**: Use specific commit hashes for production
- **Regular Updates**: Keep dependencies updated for security patches
- **Minimize Dependencies**: Only include necessary dependencies

## Maintenance

### Regular Tasks
- [ ] Update dependencies monthly
- [ ] Review security advisories
- [ ] Test after dependency updates
- [ ] Update documentation as needed

### Before Production
- [ ] Audit all dependencies
- [ ] Pin specific versions
- [ ] Test thoroughly
- [ ] Document version requirements
