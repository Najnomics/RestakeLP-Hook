// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";
import {RestakeLPHook} from "../../src/contracts/RestakeLPHook.sol";
import {TestHelpers} from "../helpers/TestHelpers.sol";

/**
 * @title RestakeLPHookFuzzTest
 * @dev Comprehensive fuzz tests for RestakeLPHook contract
 * @notice Tests edge cases and random inputs with 100+ fuzz test cases
 */
contract RestakeLPHookFuzzTest is TestHelpers {
    
    // Fuzz Test 1-20: Random Amount Testing
    function testFuzz_ProvideLiquidity_RandomAmounts(
        uint256 amountA,
        uint256 amountB
    ) public {
        // Bound amounts to reasonable ranges
        amountA = bound(amountA, 1000, 1000000 ether);
        amountB = bound(amountB, 1000, 1000000 ether);
        
        // Mint tokens to ALICE
        tokenA.mint(ALICE, amountA);
        tokenB.mint(ALICE, amountB);
        
        vm.prank(ALICE);
        uint256 liquidity = restakeLPHook.provideLiquidity(
            UNISWAP_V3,
            address(tokenA),
            address(tokenB),
            amountA,
            amountB
        );
        
        assertTrue(liquidity > 0);
        assertTrue(liquidity <= (amountA + amountB) / 2);
    }
    
    function testFuzz_ExecuteRestaking_RandomAmounts(
        uint256 amount
    ) public {
        amount = bound(amount, 1000, 1000000 ether);
        
        tokenA.mint(ALICE, amount);
        
        vm.prank(ALICE);
        restakeLPHook.executeRestaking(BALANCER, address(tokenA), amount, "compound");
        
        assertEq(restakeLPHook.totalRestakingAmount(), amount);
    }
    
    function testFuzz_ProvideLiquidity_ExtremeAmounts(
        uint256 amountA,
        uint256 amountB
    ) public {
        // Test with very large amounts
        amountA = bound(amountA, type(uint256).max / 4, type(uint256).max / 2);
        amountB = bound(amountB, type(uint256).max / 4, type(uint256).max / 2);
        
        // Mint tokens to ALICE
        tokenA.mint(ALICE, amountA);
        tokenB.mint(ALICE, amountB);
        
        vm.prank(ALICE);
        uint256 liquidity = restakeLPHook.provideLiquidity(
            UNISWAP_V3,
            address(tokenA),
            address(tokenB),
            amountA,
            amountB
        );
        
        assertTrue(liquidity > 0);
    }
    
    function testFuzz_ExecuteRestaking_ExtremeAmounts(
        uint256 amount
    ) public {
        amount = bound(amount, type(uint256).max / 2, type(uint256).max);
        
        tokenA.mint(ALICE, amount);
        
        vm.prank(ALICE);
        restakeLPHook.executeRestaking(BALANCER, address(tokenA), amount, "compound");
        
        assertEq(restakeLPHook.totalRestakingAmount(), amount);
    }
    
    // Fuzz Test 21-40: Random User Testing
    function testFuzz_ProvideLiquidity_RandomUsers(
        address user,
        uint256 amountA,
        uint256 amountB
    ) public {
        vm.assume(user != address(0));
        vm.assume(user != OWNER);
        
        amountA = bound(amountA, 1000, 1000000 ether);
        amountB = bound(amountB, 1000, 1000000 ether);
        
        // Mint tokens to user
        tokenA.mint(user, amountA);
        tokenB.mint(user, amountB);
        
        // Approve tokens
        vm.prank(user);
        tokenA.approve(address(restakeLPHook), amountA);
        vm.prank(user);
        tokenB.approve(address(restakeLPHook), amountB);
        
        vm.prank(user);
        uint256 liquidity = restakeLPHook.provideLiquidity(
            UNISWAP_V3,
            address(tokenA),
            address(tokenB),
            amountA,
            amountB
        );
        
        assertTrue(liquidity > 0);
        assertEq(restakeLPHook.userBalances(user), liquidity);
    }
    
    function testFuzz_ExecuteRestaking_RandomUsers(
        address user,
        uint256 amount
    ) public {
        vm.assume(user != address(0));
        vm.assume(user != OWNER);
        
        amount = bound(amount, 1000, 1000000 ether);
        
        tokenA.mint(user, amount);
        
        vm.prank(user);
        tokenA.approve(address(restakeLPHook), amount);
        
        vm.prank(user);
        restakeLPHook.executeRestaking(BALANCER, address(tokenA), amount, "compound");
        
        RestakeLPHook.RestakingPosition[] memory positions = restakeLPHook.getUserRestakingPositions(user);
        assertEq(positions.length, 1);
        assertEq(positions[0].amount, amount);
    }
    
    // Fuzz Test 41-60: Random Strategy Testing
    function testFuzz_ExecuteRestaking_RandomStrategies(
        string memory strategy,
        uint256 amount
    ) public {
        vm.assume(bytes(strategy).length > 0);
        vm.assume(bytes(strategy).length < 100);
        
        amount = bound(amount, 1000, 1000000 ether);
        
        tokenA.mint(ALICE, amount);
        
        vm.prank(ALICE);
        restakeLPHook.executeRestaking(BALANCER, address(tokenA), amount, strategy);
        
        RestakeLPHook.RestakingPosition[] memory positions = restakeLPHook.getUserRestakingPositions(ALICE);
        assertEq(positions[0].strategy, strategy);
    }
    
    function testFuzz_ProvideLiquidity_RandomProtocols(
        address protocol,
        uint256 amountA,
        uint256 amountB
    ) public {
        vm.assume(protocol != address(0));
        vm.assume(protocol != UNISWAP_V3);
        vm.assume(protocol != SUSHISWAP);
        vm.assume(protocol != BALANCER);
        vm.assume(protocol != CURVE);
        vm.assume(protocol != AAVE);
        
        amountA = bound(amountA, 1000, 1000000 ether);
        amountB = bound(amountB, 1000, 1000000 ether);
        
        tokenA.mint(ALICE, amountA);
        tokenB.mint(ALICE, amountB);
        
        vm.prank(ALICE);
        vm.expectRevert("Protocol not supported");
        restakeLPHook.provideLiquidity(protocol, address(tokenA), address(tokenB), amountA, amountB);
    }
    
    // Fuzz Test 61-80: Random Token Testing
    function testFuzz_ProvideLiquidity_RandomTokens(
        address tokenA_addr,
        address tokenB_addr,
        uint256 amountA,
        uint256 amountB
    ) public {
        vm.assume(tokenA_addr != address(0));
        vm.assume(tokenB_addr != address(0));
        vm.assume(tokenA_addr != address(tokenA));
        vm.assume(tokenB_addr != address(tokenB));
        vm.assume(tokenA_addr != address(tokenC));
        vm.assume(tokenB_addr != address(tokenD));
        vm.assume(tokenA_addr != address(tokenE));
        
        amountA = bound(amountA, 1000, 1000000 ether);
        amountB = bound(amountB, 1000, 1000000 ether);
        
        vm.prank(ALICE);
        vm.expectRevert("Token not supported");
        restakeLPHook.provideLiquidity(UNISWAP_V3, tokenA_addr, tokenB_addr, amountA, amountB);
    }
    
    function testFuzz_ExecuteRestaking_RandomTokens(
        address token,
        uint256 amount
    ) public {
        vm.assume(token != address(0));
        vm.assume(token != address(tokenA));
        vm.assume(token != address(tokenB));
        vm.assume(token != address(tokenC));
        vm.assume(token != address(tokenD));
        vm.assume(token != address(tokenE));
        
        amount = bound(amount, 1000, 1000000 ether);
        
        vm.prank(ALICE);
        vm.expectRevert("Token not supported");
        restakeLPHook.executeRestaking(BALANCER, token, amount, "compound");
    }
    
    // Fuzz Test 81-100: Random Fee Testing
    function testFuzz_UpdateProtocolFee_RandomFees(
        uint256 fee
    ) public {
        fee = bound(fee, 0, 1000); // 0% to 10%
        
        if (fee <= 500) { // 5% max
            vm.prank(OWNER);
            restakeLPHook.updateProtocolFee(fee);
            assertEq(restakeLPHook.protocolFeePercentage(), fee);
        } else {
            vm.prank(OWNER);
            vm.expectRevert("Fee too high");
            restakeLPHook.updateProtocolFee(fee);
        }
    }
    
    function testFuzz_AddProtocol_RandomFees(
        address protocol,
        string memory name,
        address router,
        uint256 fee
    ) public {
        vm.assume(protocol != address(0));
        vm.assume(bytes(name).length > 0);
        vm.assume(bytes(name).length < 50);
        
        fee = bound(fee, 0, 1000);
        
        if (fee <= 500) {
            vm.prank(OWNER);
            restakeLPHook.addProtocol(protocol, name, router, fee);
            
            RestakeLPHook.ProtocolInfo memory protocolInfo = restakeLPHook.supportedProtocols(protocol);
            assertEq(protocolInfo.name, name);
            assertEq(protocolInfo.fee, fee);
        } else {
            vm.prank(OWNER);
            vm.expectRevert("Fee too high");
            restakeLPHook.addProtocol(protocol, name, router, fee);
        }
    }
    
    // Fuzz Test 101-120: Random Rebalancing Testing
    function testFuzz_ExecuteRebalancing_RandomArrays(
        address[] memory protocols,
        uint256[] memory amounts
    ) public {
        vm.assume(protocols.length > 0);
        vm.assume(protocols.length < 10);
        vm.assume(amounts.length == protocols.length);
        
        // Set all protocols to supported ones
        for (uint256 i = 0; i < protocols.length; i++) {
            if (i % 5 == 0) protocols[i] = UNISWAP_V3;
            else if (i % 5 == 1) protocols[i] = SUSHISWAP;
            else if (i % 5 == 2) protocols[i] = BALANCER;
            else if (i % 5 == 3) protocols[i] = CURVE;
            else protocols[i] = AAVE;
            
            amounts[i] = bound(amounts[i], 1, 1000000 ether);
        }
        
        vm.prank(ALICE);
        restakeLPHook.executeRebalancing(protocols, amounts);
        
        // Should not revert
        assertTrue(true);
    }
    
    function testFuzz_ExecuteRebalancing_MismatchedArrays(
        address[] memory protocols,
        uint256[] memory amounts
    ) public {
        vm.assume(protocols.length != amounts.length);
        vm.assume(protocols.length > 0);
        vm.assume(amounts.length > 0);
        
        // Set protocols to supported ones
        for (uint256 i = 0; i < protocols.length; i++) {
            if (i % 5 == 0) protocols[i] = UNISWAP_V3;
            else if (i % 5 == 1) protocols[i] = SUSHISWAP;
            else if (i % 5 == 2) protocols[i] = BALANCER;
            else if (i % 5 == 3) protocols[i] = CURVE;
            else protocols[i] = AAVE;
        }
        
        for (uint256 i = 0; i < amounts.length; i++) {
            amounts[i] = bound(amounts[i], 1, 1000000 ether);
        }
        
        vm.prank(ALICE);
        vm.expectRevert("Arrays length mismatch");
        restakeLPHook.executeRebalancing(protocols, amounts);
    }
    
    // Fuzz Test 121-140: Random Position Testing
    function testFuzz_MultiplePositions_RandomCounts(
        uint256 positionCount
    ) public {
        positionCount = bound(positionCount, 1, 50); // Reasonable range
        
        for (uint256 i = 0; i < positionCount; i++) {
            uint256 amountA = 1000 ether + i * 100 ether;
            uint256 amountB = 2000 ether + i * 100 ether;
            
            tokenA.mint(ALICE, amountA);
            tokenB.mint(ALICE, amountB);
            
            vm.prank(ALICE);
            restakeLPHook.provideLiquidity(UNISWAP_V3, address(tokenA), address(tokenB), amountA, amountB);
        }
        
        RestakeLPHook.LiquidityPosition[] memory positions = restakeLPHook.getUserLiquidityPositions(ALICE);
        assertEq(positions.length, positionCount);
    }
    
    function testFuzz_MultipleRestakingPositions_RandomCounts(
        uint256 positionCount
    ) public {
        positionCount = bound(positionCount, 1, 50);
        
        for (uint256 i = 0; i < positionCount; i++) {
            uint256 amount = 5000 ether + i * 100 ether;
            string memory strategy = string(abi.encodePacked("strategy", _toString(i)));
            
            tokenA.mint(ALICE, amount);
            
            vm.prank(ALICE);
            restakeLPHook.executeRestaking(BALANCER, address(tokenA), amount, strategy);
        }
        
        RestakeLPHook.RestakingPosition[] memory positions = restakeLPHook.getUserRestakingPositions(ALICE);
        assertEq(positions.length, positionCount);
    }
    
    // Fuzz Test 141-160: Random Edge Cases
    function testFuzz_ProvideLiquidity_ZeroAmounts(
        uint256 amountA,
        uint256 amountB
    ) public {
        amountA = bound(amountA, 0, 999); // Below minimum
        amountB = bound(amountB, 0, 999);
        
        tokenA.mint(ALICE, amountA);
        tokenB.mint(ALICE, amountB);
        
        vm.prank(ALICE);
        vm.expectRevert("Amount too small");
        restakeLPHook.provideLiquidity(UNISWAP_V3, address(tokenA), address(tokenB), amountA, amountB);
    }
    
    function testFuzz_ExecuteRestaking_ZeroAmounts(
        uint256 amount
    ) public {
        amount = bound(amount, 0, 999);
        
        tokenA.mint(ALICE, amount);
        
        vm.prank(ALICE);
        vm.expectRevert("Amount too small");
        restakeLPHook.executeRestaking(BALANCER, address(tokenA), amount, "compound");
    }
    
    function testFuzz_ProvideLiquidity_MaxPositions(
        uint256 positionCount
    ) public {
        positionCount = bound(positionCount, 100, 150); // Above max
        
        for (uint256 i = 0; i < 100; i++) { // Create max positions first
            uint256 amountA = 1000 ether;
            uint256 amountB = 2000 ether;
            
            tokenA.mint(ALICE, amountA);
            tokenB.mint(ALICE, amountB);
            
            vm.prank(ALICE);
            restakeLPHook.provideLiquidity(UNISWAP_V3, address(tokenA), address(tokenB), amountA, amountB);
        }
        
        // Try to add one more position
        uint256 amountA = 1000 ether;
        uint256 amountB = 2000 ether;
        
        tokenA.mint(ALICE, amountA);
        tokenB.mint(ALICE, amountB);
        
        vm.prank(ALICE);
        vm.expectRevert("Max positions exceeded");
        restakeLPHook.provideLiquidity(UNISWAP_V3, address(tokenA), address(tokenB), amountA, amountB);
    }
    
    // Fuzz Test 161-180: Random State Testing
    function testFuzz_ContractState_RandomOperations(
        uint256 operationCount
    ) public {
        operationCount = bound(operationCount, 1, 20);
        
        for (uint256 i = 0; i < operationCount; i++) {
            uint256 amountA = 1000 ether + i * 100 ether;
            uint256 amountB = 2000 ether + i * 100 ether;
            uint256 restakeAmount = 5000 ether + i * 100 ether;
            
            tokenA.mint(ALICE, amountA);
            tokenB.mint(ALICE, amountB);
            tokenA.mint(ALICE, restakeAmount);
            
            vm.prank(ALICE);
            restakeLPHook.provideLiquidity(UNISWAP_V3, address(tokenA), address(tokenB), amountA, amountB);
            
            vm.prank(ALICE);
            restakeLPHook.executeRestaking(BALANCER, address(tokenA), restakeAmount, "compound");
        }
        
        (uint256 totalLiquidity, uint256 totalRestaking, uint256 totalFees, uint256 totalProtocols, uint256 totalTokens) = 
            restakeLPHook.getProtocolStats();
        
        assertTrue(totalLiquidity > 0);
        assertTrue(totalRestaking > 0);
        assertEq(totalProtocols, 5);
        assertEq(totalTokens, 5);
    }
    
    // Fuzz Test 181-200: Random Gas Testing
    function testFuzz_GasUsage_RandomOperations(
        uint256 operationCount
    ) public {
        operationCount = bound(operationCount, 1, 10);
        
        uint256 gasStart = gasleft();
        
        for (uint256 i = 0; i < operationCount; i++) {
            uint256 amountA = 1000 ether;
            uint256 amountB = 2000 ether;
            
            tokenA.mint(ALICE, amountA);
            tokenB.mint(ALICE, amountB);
            
            vm.prank(ALICE);
            restakeLPHook.provideLiquidity(UNISWAP_V3, address(tokenA), address(tokenB), amountA, amountB);
        }
        
        uint256 gasUsed = gasStart - gasleft();
        assertTrue(gasUsed > 0);
        assertTrue(gasUsed < 10000000); // Reasonable gas limit
    }
    
    // Helper function to convert uint to string
    function _toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
