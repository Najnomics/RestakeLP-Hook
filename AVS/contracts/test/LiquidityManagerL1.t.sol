// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

import {LiquidityManagerL1} from "@project/l1-contracts/LiquidityManagerL1.sol";

contract LiquidityManagerL1Test is Test {
    LiquidityManagerL1 public liquidityManagerL1;
    ERC20Mock public tokenA;
    ERC20Mock public tokenB;
    address public user = address(0x1);
    address public protocol = address(0x2);

    function setUp() public {
        // Deploy the LiquidityManagerL1 contract
        liquidityManagerL1 = new LiquidityManagerL1();
        
        // Deploy mock tokens
        tokenA = new ERC20Mock();
        tokenB = new ERC20Mock();
        
        // Add supported protocols and tokens
        liquidityManagerL1.addSupportedProtocol(protocol);
        liquidityManagerL1.addSupportedToken(address(tokenA));
        liquidityManagerL1.addSupportedToken(address(tokenB));
        
        // Mint tokens to user
        tokenA.mint(user, 1000 ether);
        tokenB.mint(user, 1000 ether);
        
        // Approve tokens
        vm.prank(user);
        tokenA.approve(address(liquidityManagerL1), type(uint256).max);
        vm.prank(user);
        tokenB.approve(address(liquidityManagerL1), type(uint256).max);
    }

    function testAddSupportedProtocol() public {
        address newProtocol = address(0x3);
        liquidityManagerL1.addSupportedProtocol(newProtocol);
        assertTrue(liquidityManagerL1.supportedProtocols(newProtocol));
    }

    function testAddSupportedToken() public {
        ERC20Mock newToken = new ERC20Mock();
        liquidityManagerL1.addSupportedToken(address(newToken));
        assertTrue(liquidityManagerL1.supportedTokens(address(newToken)));
    }

    function testProvideLiquidity() public {
        uint256 amountA = 100 ether;
        uint256 amountB = 200 ether;
        
        vm.prank(user);
        uint256 liquidity = liquidityManagerL1.provideLiquidity(
            protocol,
            address(tokenA),
            address(tokenB),
            amountA,
            amountB
        );
        
        // Check that liquidity was returned
        assertTrue(liquidity > 0);
        
        // Check user positions
        LiquidityManagerL1.LiquidityPosition[] memory positions = liquidityManagerL1.getUserLiquidityPositions(user);
        assertEq(positions.length, 1);
        assertEq(positions[0].protocol, protocol);
        assertEq(positions[0].tokenA, address(tokenA));
        assertEq(positions[0].tokenB, address(tokenB));
        assertEq(positions[0].amountA, amountA);
        assertEq(positions[0].amountB, amountB);
        assertEq(positions[0].liquidity, liquidity);
    }

    function testExecuteRestaking() public {
        uint256 amount = 100 ether;
        string memory strategy = "compound";
        
        vm.prank(user);
        liquidityManagerL1.executeRestaking(
            protocol,
            address(tokenA),
            amount,
            strategy
        );
        
        // Check user restaking positions
        LiquidityManagerL1.RestakingPosition[] memory positions = liquidityManagerL1.getUserRestakingPositions(user);
        assertEq(positions.length, 1);
        assertEq(positions[0].protocol, protocol);
        assertEq(positions[0].token, address(tokenA));
        assertEq(positions[0].amount, amount);
        assertEq(positions[0].strategy, strategy);
    }

    function testExecuteRebalancing() public {
        address[] memory protocols = new address[](2);
        protocols[0] = protocol;
        protocols[1] = address(0x3);
        
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100 ether;
        amounts[1] = 200 ether;
        
        vm.prank(user);
        liquidityManagerL1.executeRebalancing(protocols, amounts);
        
        // Rebalancing should complete without reverting
        assertTrue(true);
    }

    function testFailProvideLiquidityUnsupportedProtocol() public {
        address unsupportedProtocol = address(0x4);
        
        vm.prank(user);
        liquidityManagerL1.provideLiquidity(
            unsupportedProtocol,
            address(tokenA),
            address(tokenB),
            100 ether,
            200 ether
        );
    }

    function testFailProvideLiquidityUnsupportedToken() public {
        ERC20Mock unsupportedToken = new ERC20Mock();
        
        vm.prank(user);
        liquidityManagerL1.provideLiquidity(
            protocol,
            address(unsupportedToken),
            address(tokenB),
            100 ether,
            200 ether
        );
    }

    function testEmergencyWithdraw() public {
        // First provide some liquidity
        vm.prank(user);
        liquidityManagerL1.provideLiquidity(
            protocol,
            address(tokenA),
            address(tokenB),
            100 ether,
            200 ether
        );
        
        // Owner can emergency withdraw
        uint256 balanceBefore = tokenA.balanceOf(address(liquidityManagerL1));
        liquidityManagerL1.emergencyWithdraw(address(tokenA), balanceBefore);
        
        assertEq(tokenA.balanceOf(address(liquidityManagerL1)), 0);
    }
}
