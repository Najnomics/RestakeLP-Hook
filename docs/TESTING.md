# RestakeLP Hook AVS - Testing Guide

## Test Suite Overview

The project includes a comprehensive test suite with **176 tests** covering all aspects of the system:

- **Unit Tests**: 136 tests
- **Fuzz Tests**: 21 tests  
- **Integration Tests**: 15 tests
- **Test Runner**: 4 tests

## Test Coverage

- **Line Coverage**: 89.23% (348/390 lines)
- **Statement Coverage**: 88.89% (320/360 statements)
- **Function Coverage**: 86.76% (59/68 functions)
- **Branch Coverage**: 4.00% (4/100 branches)

## Running Tests

### All Tests
```bash
# Run complete test suite
forge test

# Run with detailed output
forge test -vvv

# Run with gas reporting
forge test --gas-report
```

### Unit Tests
```bash
# Run all unit tests
forge test --match-contract "*Unit*"

# Run specific unit test
forge test --match-test "test_ProvideLiquidity_Success"

# Run with coverage
forge coverage --match-contract "*Unit*"
```

### Fuzz Tests
```bash
# Run all fuzz tests
forge test --match-contract "*Fuzz*"

# Run specific fuzz test
forge test --match-test "testFuzz_ProvideLiquidity_RandomAmounts"

# Run with more fuzz runs
forge test --match-contract "*Fuzz*" --fuzz-runs 1000
```

### Integration Tests
```bash
# Run all integration tests
forge test --match-contract "*Integration*"

# Run specific integration test
forge test --match-test "test_CompleteLiquidityWorkflow"
```

## Test Categories

### Unit Tests (136 tests)

#### RestakeLPHook Unit Tests (53 tests)
- Constructor and initialization
- Protocol management
- Token management
- Liquidity provision
- Restaking execution
- Rebalancing operations
- Access control
- Error handling
- Edge cases

#### LiquidityManager Unit Tests (42 tests)
- Pool management
- Liquidity operations
- Yield harvesting
- Strategy management
- Position tracking
- Emergency functions
- Access control

#### YieldOptimizer Unit Tests (41 tests)
- Strategy management
- Protocol integration
- Yield execution
- Allocation management
- Rebalancing
- Emergency functions
- Access control

### Fuzz Tests (21 tests)

#### Random Input Testing
- `testFuzz_ProvideLiquidity_RandomAmounts`: Random liquidity amounts
- `testFuzz_ExecuteRestaking_RandomAmounts`: Random restaking amounts
- `testFuzz_ExecuteRestaking_RandomStrategies`: Random strategy names
- `testFuzz_ExecuteRestaking_RandomUsers`: Random user addresses
- `testFuzz_UpdateProtocolFee_RandomFees`: Random fee percentages

#### Extreme Value Testing
- `testFuzz_ProvideLiquidity_ExtremeAmounts`: Extreme liquidity amounts
- `testFuzz_ExecuteRestaking_ExtremeAmounts`: Extreme restaking amounts
- `testFuzz_ProvideLiquidity_MaxPositions`: Maximum position testing

#### State Testing
- `testFuzz_ContractState_RandomOperations`: Random operation sequences
- `testFuzz_MultiplePositions_RandomCounts`: Random position counts
- `testFuzz_MultipleRestakingPositions_RandomCounts`: Random restaking counts

### Integration Tests (15 tests)

#### Workflow Testing
- `test_CompleteLiquidityWorkflow`: End-to-end liquidity workflow
- `test_CompleteRestakingWorkflow`: End-to-end restaking workflow
- `test_ComplexLiquidityManagement`: Complex liquidity scenarios
- `test_ComplexRestakingScenario`: Complex restaking scenarios

#### Multi-User Testing
- `test_MultiUserLiquidityProvision`: Multiple users providing liquidity
- `test_MultiUserRestaking`: Multiple users restaking
- `test_MultiUserYieldOptimization`: Multiple users optimizing yield

#### Performance Testing
- `test_Performance_LargeScaleOperations`: Large-scale operations
- `test_GasOptimization_MultipleOperations`: Gas optimization testing

#### State Consistency Testing
- `test_StateConsistency_AfterRebalancing`: State after rebalancing
- `test_StateConsistency_CrossContract`: Cross-contract state consistency

## Test Helpers

### TestHelpers.sol
Utility functions for testing:
- `_generateRandomAmount()`: Generate random amounts
- `_generateRandomAddress()`: Generate random addresses
- `_generateRandomString()`: Generate random strings
- `_createLiquidityPosition()`: Create test liquidity positions
- `_createRestakingPosition()`: Create test restaking positions

## Coverage Analysis

### Generate Coverage Report
```bash
# Standard coverage
forge coverage

# Coverage with IR minimum
forge coverage --ir-minimum

# Coverage with detailed report
forge coverage --report lcov

# Coverage for specific contracts
forge coverage --match-contract "RestakeLPHook"
```

### Coverage Targets
- **Line Coverage**: >90%
- **Statement Coverage**: >90%
- **Function Coverage**: >95%
- **Branch Coverage**: >80%

## Test Data

### Test Tokens
- `TestTokenA`: ERC20 token for testing
- `TestTokenB`: ERC20 token for testing
- `TestTokenC`: ERC20 token for testing

### Test Addresses
- `OWNER`: Contract owner address
- `ALICE`: Test user address
- `BOB`: Test user address
- `CHARLIE`: Test user address

### Test Protocols
- `UNISWAP_V3`: Uniswap V3 protocol
- `BALANCER`: Balancer protocol
- `AAVE`: Aave protocol
- `CURVE`: Curve protocol
- `SUSHISWAP`: SushiSwap protocol

## Debugging Tests

### Verbose Output
```bash
# Maximum verbosity
forge test -vvvv

# Show gas usage
forge test --gas-report

# Show test traces
forge test --trace
```

### Debug Specific Tests
```bash
# Debug specific test
forge test --match-test "test_ProvideLiquidity_Success" -vvvv

# Debug with trace
forge test --match-test "test_ProvideLiquidity_Success" --trace
```

### Test Isolation
```bash
# Run single test file
forge test --match-path "test/unit/RestakeLPHookUnit.t.sol"

# Run single test
forge test --match-test "test_ProvideLiquidity_Success"
```

## Continuous Integration

### GitHub Actions
The project includes GitHub Actions workflows for:
- Running tests on every commit
- Generating coverage reports
- Running security analysis
- Deploying to testnets

### Pre-commit Hooks
```bash
# Install pre-commit hooks
make install-hooks

# Run pre-commit checks
make pre-commit
```

## Best Practices

### Writing Tests
1. **Test Naming**: Use descriptive test names
2. **Test Structure**: Follow Arrange-Act-Assert pattern
3. **Test Isolation**: Each test should be independent
4. **Test Coverage**: Aim for high coverage
5. **Edge Cases**: Test boundary conditions

### Test Organization
1. **Group Related Tests**: Use `describe` blocks
2. **Use Helpers**: Leverage test helper functions
3. **Mock External Dependencies**: Use mocks for external calls
4. **Test Error Conditions**: Test all error paths
5. **Test Gas Usage**: Monitor gas consumption

### Performance Testing
1. **Gas Optimization**: Test gas usage
2. **Load Testing**: Test with large datasets
3. **Stress Testing**: Test under extreme conditions
4. **Memory Testing**: Test memory usage
5. **Time Testing**: Test execution time
