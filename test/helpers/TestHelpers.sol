// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {RestakeLPHook} from "../../src/contracts/RestakeLPHook.sol";
import {LiquidityManager} from "../../src/contracts/LiquidityManager.sol";
import {YieldOptimizer} from "../../src/contracts/YieldOptimizer.sol";

/**
 * @title TestHelpers
 * @dev Comprehensive test utilities for RestakeLP Hook testing
 */
contract TestHelpers is Test {
    // Test addresses
    address public constant ALICE = address(0x1);
    address public constant BOB = address(0x2);
    address public constant CHARLIE = address(0x3);
    address public constant DAVE = address(0x4);
    address public constant EVE = address(0x5);
    address public constant OWNER = address(0x6);
    
    // Test protocols
    address public constant UNISWAP_V3 = address(0x7);
    address public constant SUSHISWAP = address(0x8);
    address public constant BALANCER = address(0x9);
    address public constant CURVE = address(0xA);
    address public constant AAVE = address(0xB);
    
    // Test tokens
    ERC20Mock public tokenA;
    ERC20Mock public tokenB;
    ERC20Mock public tokenC;
    ERC20Mock public tokenD;
    ERC20Mock public tokenE;
    
    // Contract instances
    RestakeLPHook public restakeLPHook;
    LiquidityManager public liquidityManager;
    YieldOptimizer public yieldOptimizer;
    
    // Test constants
    uint256 public constant INITIAL_SUPPLY = 1000000 ether;
    uint256 public constant TEST_AMOUNT = 1000 ether;
    uint256 public constant SMALL_AMOUNT = 100 ether;
    uint256 public constant LARGE_AMOUNT = 10000 ether;
    
    function setUp() public virtual {
        // Deploy mock tokens
        tokenA = new ERC20Mock();
        tokenB = new ERC20Mock();
        tokenC = new ERC20Mock();
        tokenD = new ERC20Mock();
        tokenE = new ERC20Mock();
        
        // Mint tokens to test addresses
        tokenA.mint(ALICE, INITIAL_SUPPLY);
        tokenA.mint(BOB, INITIAL_SUPPLY);
        tokenA.mint(CHARLIE, INITIAL_SUPPLY);
        tokenA.mint(DAVE, INITIAL_SUPPLY);
        tokenA.mint(EVE, INITIAL_SUPPLY);
        
        tokenB.mint(ALICE, INITIAL_SUPPLY);
        tokenB.mint(BOB, INITIAL_SUPPLY);
        tokenB.mint(CHARLIE, INITIAL_SUPPLY);
        tokenB.mint(DAVE, INITIAL_SUPPLY);
        tokenB.mint(EVE, INITIAL_SUPPLY);
        
        tokenC.mint(ALICE, INITIAL_SUPPLY);
        tokenC.mint(BOB, INITIAL_SUPPLY);
        tokenC.mint(CHARLIE, INITIAL_SUPPLY);
        tokenC.mint(DAVE, INITIAL_SUPPLY);
        tokenC.mint(EVE, INITIAL_SUPPLY);
        
        tokenD.mint(ALICE, INITIAL_SUPPLY);
        tokenD.mint(BOB, INITIAL_SUPPLY);
        tokenD.mint(CHARLIE, INITIAL_SUPPLY);
        tokenD.mint(DAVE, INITIAL_SUPPLY);
        tokenD.mint(EVE, INITIAL_SUPPLY);
        
        tokenE.mint(ALICE, INITIAL_SUPPLY);
        tokenE.mint(BOB, INITIAL_SUPPLY);
        tokenE.mint(CHARLIE, INITIAL_SUPPLY);
        tokenE.mint(DAVE, INITIAL_SUPPLY);
        tokenE.mint(EVE, INITIAL_SUPPLY);
        
        // Deploy contracts
        vm.prank(OWNER);
        restakeLPHook = new RestakeLPHook();
        
        vm.prank(OWNER);
        liquidityManager = new LiquidityManager();
        
        vm.prank(OWNER);
        yieldOptimizer = new YieldOptimizer();
        
        // Setup initial state
        _setupInitialState();
    }
    
    function _setupInitialState() internal {
        // Add protocols to RestakeLPHook
        vm.startPrank(OWNER);
        restakeLPHook.addProtocol(UNISWAP_V3, "Uniswap V3", UNISWAP_V3, 300); // 3%
        restakeLPHook.addProtocol(SUSHISWAP, "SushiSwap", SUSHISWAP, 250); // 2.5%
        restakeLPHook.addProtocol(BALANCER, "Balancer", BALANCER, 200); // 2%
        restakeLPHook.addProtocol(CURVE, "Curve", CURVE, 150); // 1.5%
        restakeLPHook.addProtocol(AAVE, "Aave", AAVE, 100); // 1%
        
        // Add tokens to RestakeLPHook
        restakeLPHook.addToken(address(tokenA), "TokenA", 18, 1000);
        restakeLPHook.addToken(address(tokenB), "TokenB", 18, 1000);
        restakeLPHook.addToken(address(tokenC), "TokenC", 18, 1000);
        restakeLPHook.addToken(address(tokenD), "TokenD", 18, 1000);
        restakeLPHook.addToken(address(tokenE), "TokenE", 18, 1000);
        vm.stopPrank();
        
        // Add pools to LiquidityManager
        vm.startPrank(OWNER);
        liquidityManager.addPool(UNISWAP_V3, address(tokenA), address(tokenB), 3000);
        liquidityManager.addPool(SUSHISWAP, address(tokenB), address(tokenC), 2500);
        liquidityManager.addPool(BALANCER, address(tokenC), address(tokenD), 2000);
        liquidityManager.addPool(CURVE, address(tokenD), address(tokenE), 1500);
        liquidityManager.addPool(AAVE, address(tokenA), address(tokenE), 1000);
        vm.stopPrank();
        
        // Add protocols to YieldOptimizer
        vm.startPrank(OWNER);
        yieldOptimizer.addProtocol(UNISWAP_V3, 1000, 0); // 10% APY
        yieldOptimizer.addProtocol(SUSHISWAP, 800, 0); // 8% APY
        yieldOptimizer.addProtocol(BALANCER, 600, 0); // 6% APY
        yieldOptimizer.addProtocol(CURVE, 400, 0); // 4% APY
        yieldOptimizer.addProtocol(AAVE, 200, 0); // 2% APY
        vm.stopPrank();
        
        // Approve tokens for all users
        _approveTokensForUsers();
    }
    
    function _approveTokensForUsers() internal {
        address[] memory users = new address[](5);
        users[0] = ALICE;
        users[1] = BOB;
        users[2] = CHARLIE;
        users[3] = DAVE;
        users[4] = EVE;
        
        IERC20[] memory tokens = new IERC20[](5);
        tokens[0] = tokenA;
        tokens[1] = tokenB;
        tokens[2] = tokenC;
        tokens[3] = tokenD;
        tokens[4] = tokenE;
        
        for (uint256 i = 0; i < users.length; i++) {
            for (uint256 j = 0; j < tokens.length; j++) {
                vm.prank(users[i]);
                tokens[j].approve(address(restakeLPHook), type(uint256).max);
                vm.prank(users[i]);
                tokens[j].approve(address(liquidityManager), type(uint256).max);
            }
        }
    }
    
    // Helper functions for common test operations
    function _createLiquidityPosition(
        address user,
        address protocol,
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB
    ) internal returns (uint256 liquidity) {
        vm.prank(user);
        return restakeLPHook.provideLiquidity(protocol, tokenA, tokenB, amountA, amountB);
    }
    
    function _createRestakingPosition(
        address user,
        address protocol,
        address token,
        uint256 amount,
        string memory strategy
    ) internal {
        vm.prank(user);
        restakeLPHook.executeRestaking(protocol, token, amount, strategy);
    }
    
    function _addLiquidityToPool(
        address user,
        address pool,
        uint256 amount0,
        uint256 amount1,
        string memory strategy
    ) internal returns (uint256 liquidity) {
        vm.prank(user);
        return liquidityManager.addLiquidity(pool, amount0, amount1, strategy);
    }
    
    function _executeYieldStrategy(
        address user,
        string memory strategyName,
        uint256 amount
    ) internal returns (uint256 yield) {
        vm.prank(user);
        return yieldOptimizer.executeStrategy(strategyName, amount);
    }
    
    // Helper functions for assertions
    function _assertLiquidityPosition(
        address user,
        uint256 positionIndex,
        address expectedProtocol,
        address expectedTokenA,
        address expectedTokenB,
        uint256 expectedAmountA,
        uint256 expectedAmountB
    ) internal view {
        RestakeLPHook.LiquidityPosition[] memory positions = restakeLPHook.getUserLiquidityPositions(user);
        require(positionIndex < positions.length, "Position index out of bounds");
        
        RestakeLPHook.LiquidityPosition memory position = positions[positionIndex];
        assertEq(position.protocol, expectedProtocol);
        assertEq(position.tokenA, expectedTokenA);
        assertEq(position.tokenB, expectedTokenB);
        assertEq(position.amountA, expectedAmountA);
        assertEq(position.amountB, expectedAmountB);
        assertTrue(position.isActive);
    }
    
    function _assertRestakingPosition(
        address user,
        uint256 positionIndex,
        address expectedProtocol,
        address expectedToken,
        uint256 expectedAmount,
        string memory expectedStrategy
    ) internal view {
        RestakeLPHook.RestakingPosition[] memory positions = restakeLPHook.getUserRestakingPositions(user);
        require(positionIndex < positions.length, "Position index out of bounds");
        
        RestakeLPHook.RestakingPosition memory position = positions[positionIndex];
        assertEq(position.protocol, expectedProtocol);
        assertEq(position.token, expectedToken);
        assertEq(position.amount, expectedAmount);
        assertEq(position.strategy, expectedStrategy);
        assertTrue(position.isActive);
    }
    
    // Helper functions for fuzz testing
    function _generateRandomAmount(uint256 min, uint256 max) internal pure returns (uint256) {
        uint256 random = uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)));
        return min + (random % (max - min + 1));
    }
    
    function _generateRandomAddress() internal pure returns (address) {
        return address(uint160(uint256(keccak256(abi.encodePacked(block.timestamp, block.difficulty)))));
    }
    
    function _generateRandomString(uint256 length) internal pure returns (string memory) {
        bytes memory chars = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789";
        bytes memory result = new bytes(length);
        
        for (uint256 i = 0; i < length; i++) {
            result[i] = chars[uint256(keccak256(abi.encodePacked(block.timestamp, i))) % chars.length];
        }
        
        return string(result);
    }
    
    // Helper functions for integration testing
    function _setupComplexScenario() internal {
        // Create multiple positions across different protocols
        _createLiquidityPosition(ALICE, UNISWAP_V3, address(tokenA), address(tokenB), 1000 ether, 2000 ether);
        _createLiquidityPosition(ALICE, SUSHISWAP, address(tokenB), address(tokenC), 1500 ether, 2500 ether);
        _createRestakingPosition(ALICE, BALANCER, address(tokenA), 5000 ether, "compound");
        
        _createLiquidityPosition(BOB, CURVE, address(tokenC), address(tokenD), 3000 ether, 4000 ether);
        _createRestakingPosition(BOB, AAVE, address(tokenB), 8000 ether, "auto-compound");
        
        _createLiquidityPosition(CHARLIE, UNISWAP_V3, address(tokenD), address(tokenE), 2000 ether, 3000 ether);
        _createLiquidityPosition(CHARLIE, BALANCER, address(tokenA), address(tokenE), 4000 ether, 5000 ether);
    }
    
    // Helper functions for gas optimization testing
    function _measureGas(
        function() internal func
    ) internal returns (uint256 gasUsed) {
        uint256 gasStart = gasleft();
        func();
        gasUsed = gasStart - gasleft();
    }
    
    // Helper functions for edge case testing
    function _testZeroAmounts() internal {
        // Test with zero amounts
        vm.prank(ALICE);
        vm.expectRevert("Amount too small");
        restakeLPHook.provideLiquidity(UNISWAP_V3, address(tokenA), address(tokenB), 0, 0);
    }
    
    function _testMaxAmounts() internal {
        // Test with maximum amounts
        uint256 maxAmount = type(uint256).max / 2; // Avoid overflow
        vm.prank(ALICE);
        restakeLPHook.provideLiquidity(UNISWAP_V3, address(tokenA), address(tokenB), maxAmount, maxAmount);
    }
    
    function _testInvalidAddresses() internal {
        // Test with invalid addresses
        vm.prank(ALICE);
        vm.expectRevert("Protocol not supported");
        restakeLPHook.provideLiquidity(address(0), address(tokenA), address(tokenB), 1000 ether, 2000 ether);
    }
}
