// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {Test, console} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20Mock} from "@openzeppelin/contracts/mocks/token/ERC20Mock.sol";

import {LiquidityManagerL2} from "@project/l2-contracts/LiquidityManagerL2.sol";

contract LiquidityManagerL2Test is Test {
    LiquidityManagerL2 public liquidityManagerL2;
    address public executor = address(0x1);
    address public user = address(0x2);

    function setUp() public {
        // Deploy the LiquidityManagerL2 contract
        liquidityManagerL2 = new LiquidityManagerL2();
        
        // Authorize executor
        liquidityManagerL2.authorizeExecutor(executor);
    }

    function testAuthorizeExecutor() public {
        address newExecutor = address(0x3);
        liquidityManagerL2.authorizeExecutor(newExecutor);
        assertTrue(liquidityManagerL2.authorizedExecutors(newExecutor));
    }

    function testRevokeExecutor() public {
        liquidityManagerL2.revokeExecutor(executor);
        assertFalse(liquidityManagerL2.authorizedExecutors(executor));
    }

    function testExecuteRestakeTask() public {
        bytes32 taskId = keccak256("test-restake-task");
        string memory taskType = "restake";
        bytes memory taskData = abi.encode("test-data");
        
        vm.prank(executor);
        (bool success, bytes memory result) = liquidityManagerL2.executeTask(taskId, taskType, taskData);
        
        assertTrue(success);
        assertTrue(result.length > 0);
        
        // Check task execution record
        LiquidityManagerL2.TaskExecution memory execution = liquidityManagerL2.getTaskExecution(taskId);
        assertEq(execution.taskId, taskId);
        assertEq(execution.taskType, taskType);
        assertEq(execution.executor, executor);
        assertTrue(execution.success);
    }

    function testExecuteLiquidityTask() public {
        bytes32 taskId = keccak256("test-liquidity-task");
        string memory taskType = "liquidity";
        bytes memory taskData = abi.encode("test-data");
        
        vm.prank(executor);
        (bool success, bytes memory result) = liquidityManagerL2.executeTask(taskId, taskType, taskData);
        
        assertTrue(success);
        assertTrue(result.length > 0);
    }

    function testExecuteRebalanceTask() public {
        bytes32 taskId = keccak256("test-rebalance-task");
        string memory taskType = "rebalance";
        bytes memory taskData = abi.encode("test-data");
        
        vm.prank(executor);
        (bool success, bytes memory result) = liquidityManagerL2.executeTask(taskId, taskType, taskData);
        
        assertTrue(success);
        assertTrue(result.length > 0);
    }

    function testExecuteWithdrawTask() public {
        bytes32 taskId = keccak256("test-withdraw-task");
        string memory taskType = "withdraw";
        bytes memory taskData = abi.encode("test-data");
        
        vm.prank(executor);
        (bool success, bytes memory result) = liquidityManagerL2.executeTask(taskId, taskType, taskData);
        
        assertTrue(success);
        assertTrue(result.length > 0);
    }

    function testFailExecuteTaskUnauthorized() public {
        bytes32 taskId = keccak256("test-task");
        string memory taskType = "restake";
        bytes memory taskData = abi.encode("test-data");
        
        address unauthorizedExecutor = address(0x4);
        vm.prank(unauthorizedExecutor);
        vm.expectRevert("Not authorized executor");
        liquidityManagerL2.executeTask(taskId, taskType, taskData);
    }

    function testFailExecuteTaskInvalidType() public {
        bytes32 taskId = keccak256("test-task");
        string memory taskType = "invalid";
        bytes memory taskData = abi.encode("test-data");
        
        vm.prank(executor);
        vm.expectRevert("Invalid task type");
        liquidityManagerL2.executeTask(taskId, taskType, taskData);
    }

    function testFailExecuteTaskAlreadyExecuted() public {
        bytes32 taskId = keccak256("test-task");
        string memory taskType = "restake";
        bytes memory taskData = abi.encode("test-data");
        
        // Execute task first time
        vm.prank(executor);
        liquidityManagerL2.executeTask(taskId, taskType, taskData);
        
        // Try to execute same task again
        vm.prank(executor);
        vm.expectRevert("Task already executed");
        liquidityManagerL2.executeTask(taskId, taskType, taskData);
    }

    function testGetProtocolStats() public {
        // Execute some tasks first
        bytes32 taskId1 = keccak256("test-task-1");
        bytes32 taskId2 = keccak256("test-task-2");
        
        vm.prank(executor);
        liquidityManagerL2.executeTask(taskId1, "restake", abi.encode("data1"));
        
        vm.prank(executor);
        liquidityManagerL2.executeTask(taskId2, "liquidity", abi.encode("data2"));
        
        (uint256 totalTasks, uint256 totalLiquidity, uint256 totalRestaking) = liquidityManagerL2.getProtocolStats();
        
        assertEq(totalTasks, 2);
        // Note: totalLiquidity and totalRestaking are not updated in the mock implementation
    }

    function testEmergencyWithdraw() public {
        // Deploy a mock token and send some to the contract
        ERC20Mock token = new ERC20Mock();
        token.mint(address(liquidityManagerL2), 1000 ether);
        
        uint256 balanceBefore = token.balanceOf(address(liquidityManagerL2));
        assertTrue(balanceBefore > 0);
        
        // Owner can emergency withdraw
        liquidityManagerL2.emergencyWithdraw(address(token), balanceBefore);
        
        assertEq(token.balanceOf(address(liquidityManagerL2)), 0);
    }

    function testFailEmergencyWithdrawNotOwner() public {
        ERC20Mock token = new ERC20Mock();
        
        vm.prank(executor);
        vm.expectRevert();
        liquidityManagerL2.emergencyWithdraw(address(token), 1000 ether);
    }
}
