// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";

/**
 * @title Verify
 * @notice Script to verify deployed contracts on Etherscan
 * @dev Reads deployment addresses and verifies contracts
 */
contract Verify is Script {
    // Contract addresses (will be set from deployment)
    address public restakeLPHook;
    address public liquidityManager;
    address public yieldOptimizer;
    address public owner;
    
    function setUp() public {
        // Load deployment addresses from environment or deployment file
        // These should be set after deployment
        restakeLPHook = vm.envOr("RESTAKE_HOOK_ADDRESS", address(0));
        liquidityManager = vm.envOr("LIQUIDITY_MANAGER_ADDRESS", address(0));
        yieldOptimizer = vm.envOr("YIELD_OPTIMIZER_ADDRESS", address(0));
        owner = vm.envOr("OWNER_ADDRESS", address(0));
        
        require(restakeLPHook != address(0), "RestakeLPHook address not set");
        require(liquidityManager != address(0), "LiquidityManager address not set");
        require(yieldOptimizer != address(0), "YieldOptimizer address not set");
        require(owner != address(0), "Owner address not set");
    }
    
    function run() public {
        console.log("Verifying contracts on Etherscan...");
        console.log("RestakeLPHook:", restakeLPHook);
        console.log("LiquidityManager:", liquidityManager);
        console.log("YieldOptimizer:", yieldOptimizer);
        console.log("Owner:", owner);
        
        // Note: Contract verification is typically done via forge verify-contract
        // This script is for reference and can be used to check contract states
        
        vm.startBroadcast();
        
        // Verify contract states
        _verifyContractStates();
        
        vm.stopBroadcast();
        
        console.log("Contract verification completed!");
    }
    
    function _verifyContractStates() internal view {
        console.log("\n=== CONTRACT STATE VERIFICATION ===");
        
        // Verify RestakeLPHook
        console.log("RestakeLPHook owner:", RestakeLPHook(restakeLPHook).owner());
        console.log("RestakeLPHook paused:", RestakeLPHook(restakeLPHook).paused());
        console.log("RestakeLPHook protocol fee:", RestakeLPHook(restakeLPHook).protocolFeePercentage());
        
        // Verify LiquidityManager
        console.log("LiquidityManager owner:", LiquidityManager(liquidityManager).owner());
        
        // Verify YieldOptimizer
        console.log("YieldOptimizer owner:", YieldOptimizer(yieldOptimizer).owner());
        
        console.log("===================================\n");
    }
}

// Import contract interfaces for verification
interface RestakeLPHook {
    function owner() external view returns (address);
    function paused() external view returns (bool);
    function protocolFeePercentage() external view returns (uint256);
}

interface LiquidityManager {
    function owner() external view returns (address);
}

interface YieldOptimizer {
    function owner() external view returns (address);
}
