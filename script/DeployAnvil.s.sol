// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {RestakeLPHook} from "../src/contracts/RestakeLPHook.sol";
import {LiquidityManager} from "../src/contracts/LiquidityManager.sol";
import {YieldOptimizer} from "../src/contracts/YieldOptimizer.sol";

/**
 * @title DeployAnvil
 * @notice Deployment script for local Anvil development
 * @dev Uses test addresses and simplified setup for local development
 */
contract DeployAnvil is Script {
    // Contract instances
    RestakeLPHook public restakeLPHook;
    LiquidityManager public liquidityManager;
    YieldOptimizer public yieldOptimizer;
    
    // Test addresses for Anvil
    address public owner;
    address constant UNISWAP_V3 = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address constant BALANCER = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    address constant AAVE = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;
    address constant CURVE = 0x8301AE4fc9c624d1d396cbdaa1ed877821d7c511;
    address constant SUSHISWAP = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    
    // Test token addresses
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant USDC = 0xA0b86a33E6441b8C4C8C0e4B8b8C8C0e4B8b8C8C;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    
    function setUp() public {
        // Use default Anvil account
        owner = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;
        
        console.log("Anvil Deployer address:", owner);
        console.log("Anvil Deployer balance:", owner.balance);
    }
    
    function run() public {
        vm.startBroadcast();
        
        // Deploy contracts
        _deployContracts();
        
        // Initialize contracts
        _initializeContracts();
        
        // Setup test protocols and tokens
        _setupProtocols();
        _setupTokens();
        
        // Setup test strategies
        _setupStrategies();
        
        vm.stopBroadcast();
        
        // Log deployment results
        _logDeployment();
    }
    
    function _deployContracts() internal {
        console.log("Deploying RestakeLPHook to Anvil...");
        restakeLPHook = new RestakeLPHook(owner);
        console.log("RestakeLPHook deployed at:", address(restakeLPHook));
        
        console.log("Deploying LiquidityManager to Anvil...");
        liquidityManager = new LiquidityManager(owner);
        console.log("LiquidityManager deployed at:", address(liquidityManager));
        
        console.log("Deploying YieldOptimizer to Anvil...");
        yieldOptimizer = new YieldOptimizer(owner);
        console.log("YieldOptimizer deployed at:", address(yieldOptimizer));
    }
    
    function _initializeContracts() internal {
        console.log("Initializing contracts for Anvil...");
        
        // Set initial protocol fee (1%)
        restakeLPHook.updateProtocolFee(100);
        
        // Fund contracts with some ETH for testing
        vm.deal(address(restakeLPHook), 10 ether);
        vm.deal(address(liquidityManager), 5 ether);
        vm.deal(address(yieldOptimizer), 5 ether);
    }
    
    function _setupProtocols() internal {
        console.log("Setting up test protocols...");
        
        // Add Uniswap V3
        restakeLPHook.addProtocol(
            UNISWAP_V3,
            "Uniswap V3",
            address(0),
            100 // 1% fee
        );
        
        // Add Balancer
        restakeLPHook.addProtocol(
            BALANCER,
            "Balancer",
            address(0),
            150 // 1.5% fee
        );
        
        // Add Aave
        restakeLPHook.addProtocol(
            AAVE,
            "Aave",
            address(0),
            200 // 2% fee
        );
        
        // Add Curve
        restakeLPHook.addProtocol(
            CURVE,
            "Curve",
            address(0),
            50 // 0.5% fee
        );
        
        // Add SushiSwap
        restakeLPHook.addProtocol(
            SUSHISWAP,
            "SushiSwap",
            address(0),
            300 // 3% fee
        );
    }
    
    function _setupTokens() internal {
        console.log("Setting up test tokens...");
        
        // Add DAI
        restakeLPHook.addToken(
            DAI,
            "DAI",
            "Dai Stablecoin",
            18
        );
        
        // Add USDC
        restakeLPHook.addToken(
            USDC,
            "USDC",
            "USD Coin",
            6
        );
        
        // Add USDT
        restakeLPHook.addToken(
            USDT,
            "USDT",
            "Tether USD",
            6
        );
        
        // Add WETH
        restakeLPHook.addToken(
            WETH,
            "WETH",
            "Wrapped Ether",
            18
        );
    }
    
    function _setupStrategies() internal {
        console.log("Setting up test strategies...");
        
        // Add protocols to yield optimizer
        yieldOptimizer.addProtocol(UNISWAP_V3, 1000, 0); // 10% APY
        yieldOptimizer.addProtocol(BALANCER, 1200, 0); // 12% APY
        yieldOptimizer.addProtocol(AAVE, 800, 0); // 8% APY
        yieldOptimizer.addProtocol(CURVE, 600, 0); // 6% APY
        yieldOptimizer.addProtocol(SUSHISWAP, 900, 0); // 9% APY
        
        // Create test strategy
        address[] memory protocols = new address[](2);
        protocols[0] = UNISWAP_V3;
        protocols[1] = BALANCER;
        
        uint256[] memory weights = new uint256[](2);
        weights[0] = 5000; // 50%
        weights[1] = 5000; // 50%
        
        yieldOptimizer.addStrategy(
            "test-strategy",
            protocols,
            weights,
            500, // 5% minimum yield
            100  // 1% max slippage
        );
    }
    
    function _logDeployment() internal view {
        console.log("\n=== ANVIL DEPLOYMENT COMPLETE ===");
        console.log("RestakeLPHook:", address(restakeLPHook));
        console.log("LiquidityManager:", address(liquidityManager));
        console.log("YieldOptimizer:", address(yieldOptimizer));
        console.log("Owner:", owner);
        console.log("Anvil RPC: http://localhost:8545");
        console.log("===================================\n");
    }
}
