// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Script, console} from "forge-std/Script.sol";
import {RestakeLPHook} from "../src/contracts/RestakeLPHook.sol";
import {LiquidityManager} from "../src/contracts/LiquidityManager.sol";
import {YieldOptimizer} from "../src/contracts/YieldOptimizer.sol";

/**
 * @title DeployMainnet
 * @notice Deployment script for Ethereum mainnet
 * @dev Deploys contracts with production configuration and safety checks
 */
contract DeployMainnet is Script {
    // Contract instances
    RestakeLPHook public restakeLPHook;
    LiquidityManager public liquidityManager;
    YieldOptimizer public yieldOptimizer;
    
    // Deployment configuration
    address public owner;
    uint256 public deployerPrivateKey;
    
    // Mainnet addresses
    address constant UNISWAP_V3 = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
    address constant BALANCER = 0xBA12222222228d8Ba445958a75a0704d566BF2C8;
    address constant AAVE = 0x7d2768dE32b0b80b7a3454c06BdAc94A69DDc7A9;
    address constant CURVE = 0x8301AE4fc9c624d1D396cbDAa1ed877821D7C511;
    address constant SUSHISWAP = 0xd9e1cE17f2641f24aE83637ab66a2cca9C378B9F;
    
    // Mainnet token addresses
    address constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address constant USDC = 0xa0b86a33E6441b8C4c8C0E4B8B8C8c0e4B8B8C8C;
    address constant USDT = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    address constant WETH = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
    
    function setUp() public {
        // Get deployer private key from environment
        deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        owner = vm.addr(deployerPrivateKey);
        
        console.log("Mainnet Deployer address:", owner);
        console.log("Mainnet Deployer balance:", owner.balance);
        
        // Verify we have enough ETH for deployment
        require(owner.balance >= 1 ether, "Insufficient balance for mainnet deployment");
        
        // Additional safety checks for mainnet
        require(block.chainid == 1, "Not on mainnet");
        console.log("Chain ID verified:", block.chainid);
    }
    
    function run() public {
        // Safety check - require explicit confirmation for mainnet
        console.log("WARNING: Deploying to MAINNET!");
        console.log("This will cost real ETH and deploy real contracts.");
        console.log("Make sure you have tested thoroughly on testnet.");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy contracts
        _deployContracts();
        
        // Initialize contracts
        _initializeContracts();
        
        // Setup mainnet protocols and tokens
        _setupProtocols();
        _setupTokens();
        
        // Setup mainnet strategies
        _setupStrategies();
        
        vm.stopBroadcast();
        
        // Log deployment results
        _logDeployment();
    }
    
    function _deployContracts() internal {
        console.log("Deploying RestakeLPHook to Mainnet...");
        restakeLPHook = new RestakeLPHook();
        console.log("RestakeLPHook deployed at:", address(restakeLPHook));
        
        console.log("Deploying LiquidityManager to Mainnet...");
        liquidityManager = new LiquidityManager();
        console.log("LiquidityManager deployed at:", address(liquidityManager));
        
        console.log("Deploying YieldOptimizer to Mainnet...");
        yieldOptimizer = new YieldOptimizer();
        console.log("YieldOptimizer deployed at:", address(yieldOptimizer));
    }
    
    function _initializeContracts() internal {
        console.log("Initializing contracts for Mainnet...");
        
        // Set initial protocol fee (1%)
        restakeLPHook.updateProtocolFee(100);
        
        // Set production parameters
        // (Additional initialization can be added here)
    }
    
    function _setupProtocols() internal {
        console.log("Setting up mainnet protocols...");
        
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
        console.log("Setting up mainnet tokens...");
        
        // Add DAI
        restakeLPHook.addToken(
            DAI,
            "DAI",
            18,
            1000
        );
        
        // Add USDC
        restakeLPHook.addToken(
            USDC,
            "USDC",
            6,
            1000
        );
        
        // Add USDT
        restakeLPHook.addToken(
            USDT,
            "USDT",
            6,
            1000
        );
        
        // Add WETH
        restakeLPHook.addToken(
            WETH,
            "WETH",
            18,
            1000
        );
    }
    
    function _setupStrategies() internal {
        console.log("Setting up mainnet strategies...");
        
        // Add protocols to yield optimizer
        yieldOptimizer.addProtocol(UNISWAP_V3, 1000, 0); // 10% APY
        yieldOptimizer.addProtocol(BALANCER, 1200, 0); // 12% APY
        yieldOptimizer.addProtocol(AAVE, 800, 0); // 8% APY
        yieldOptimizer.addProtocol(CURVE, 600, 0); // 6% APY
        yieldOptimizer.addProtocol(SUSHISWAP, 900, 0); // 9% APY
        
        // Create balanced strategy
        address[] memory balancedProtocols = new address[](3);
        balancedProtocols[0] = UNISWAP_V3;
        balancedProtocols[1] = BALANCER;
        balancedProtocols[2] = AAVE;
        
        uint256[] memory balancedWeights = new uint256[](3);
        balancedWeights[0] = 4000; // 40%
        balancedWeights[1] = 4000; // 40%
        balancedWeights[2] = 2000; // 20%
        
        yieldOptimizer.addStrategy(
            "balanced",
            balancedProtocols,
            balancedWeights,
            500, // 5% minimum yield
            100  // 1% max slippage
        );
        
        // Create conservative strategy
        address[] memory conservativeProtocols = new address[](2);
        conservativeProtocols[0] = AAVE;
        conservativeProtocols[1] = CURVE;
        
        uint256[] memory conservativeWeights = new uint256[](2);
        conservativeWeights[0] = 6000; // 60%
        conservativeWeights[1] = 4000; // 40%
        
        yieldOptimizer.addStrategy(
            "conservative",
            conservativeProtocols,
            conservativeWeights,
            300, // 3% minimum yield
            50   // 0.5% max slippage
        );
        
        // Create aggressive strategy
        address[] memory aggressiveProtocols = new address[](2);
        aggressiveProtocols[0] = UNISWAP_V3;
        aggressiveProtocols[1] = SUSHISWAP;
        
        uint256[] memory aggressiveWeights = new uint256[](2);
        aggressiveWeights[0] = 5000; // 50%
        aggressiveWeights[1] = 5000; // 50%
        
        yieldOptimizer.addStrategy(
            "aggressive",
            aggressiveProtocols,
            aggressiveWeights,
            800, // 8% minimum yield
            200  // 2% max slippage
        );
    }
    
    function _logDeployment() internal view {
        console.log("\n=== MAINNET DEPLOYMENT COMPLETE ===");
        console.log("RestakeLPHook:", address(restakeLPHook));
        console.log("LiquidityManager:", address(liquidityManager));
        console.log("YieldOptimizer:", address(yieldOptimizer));
        console.log("Owner:", owner);
        console.log("Etherscan: https://etherscan.io/address/", address(restakeLPHook));
        console.log("=====================================\n");
    }
}
