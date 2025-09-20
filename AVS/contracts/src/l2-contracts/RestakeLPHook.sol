// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {IAVSTaskHook} from "@eigenlayer-contracts/src/contracts/interfaces/IAVSTaskHook.sol";
import {ITaskMailboxTypes} from "@eigenlayer-contracts/src/contracts/interfaces/ITaskMailbox.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/**
 * @title RestakeLPHook
 * @dev Task lifecycle validation for restaking and LP operations
 * @notice This contract validates and manages RestakeLP Hook task lifecycle
 */
contract RestakeLPHook is IAVSTaskHook, Ownable {
    // Events
    event TaskValidated(
        bytes32 indexed taskHash,
        address indexed caller,
        string taskType,
        bool isValid
    );

    event TaskCreated(
        bytes32 indexed taskHash,
        address indexed caller,
        uint256 fee,
        uint256 timestamp
    );

    event TaskResultSubmitted(
        bytes32 indexed taskHash,
        address indexed caller,
        bool success,
        uint256 timestamp
    );

    event FeeUpdated(
        uint256 oldFee,
        uint256 newFee,
        uint256 timestamp
    );

    // Structs
    struct TaskValidation {
        bytes32 taskHash;
        address caller;
        string taskType;
        bool isValid;
        uint256 timestamp;
    }

    // State variables
    mapping(bytes32 => TaskValidation) public taskValidations;
    mapping(address => bool) public authorizedCallers;
    mapping(string => uint256) public taskTypeFees;
    
    uint256 public baseTaskFee = 0.001 ether; // Base fee in ETH
    uint256 public totalTasksCreated;
    uint256 public totalFeesCollected;

    // Constants
    uint256 public constant MAX_FEE = 0.1 ether; // Maximum fee per task
    uint256 public constant MIN_FEE = 0.0001 ether; // Minimum fee per task

    // Modifiers
    modifier onlyAuthorizedCaller(address caller) {
        require(authorizedCallers[caller] || caller == owner(), "Not authorized caller");
        _;
    }

    modifier validFee(uint256 fee) {
        require(fee >= MIN_FEE && fee <= MAX_FEE, "Invalid fee amount");
        _;
    }

    constructor() Ownable(msg.sender) {
        // Initialize task type fees
        taskTypeFees["restake"] = 0.001 ether;
        taskTypeFees["liquidity"] = 0.002 ether;
        taskTypeFees["rebalance"] = 0.0015 ether;
        taskTypeFees["withdraw"] = 0.0005 ether;
    }

    /**
     * @dev Authorize a caller to create tasks
     * @param caller The caller address to authorize
     */
    function authorizeCaller(address caller) external onlyOwner {
        authorizedCallers[caller] = true;
    }

    /**
     * @dev Revoke caller authorization
     * @param caller The caller address to revoke
     */
    function revokeCaller(address caller) external onlyOwner {
        authorizedCallers[caller] = false;
    }

    /**
     * @dev Set fee for a specific task type
     * @param taskType The task type
     * @param fee The fee amount
     */
    function setTaskTypeFee(string memory taskType, uint256 fee) external onlyOwner validFee(fee) {
        taskTypeFees[taskType] = fee;
    }

    /**
     * @dev Set base task fee
     * @param fee The base fee amount
     */
    function setBaseTaskFee(uint256 fee) external onlyOwner validFee(fee) {
        uint256 oldFee = baseTaskFee;
        baseTaskFee = fee;
        emit FeeUpdated(oldFee, fee, block.timestamp);
    }

    /**
     * @dev Validate task before creation
     * @param caller The caller address
     * @param taskParams The task parameters
     */
    function validatePreTaskCreation(
        address caller,
        ITaskMailboxTypes.TaskParams memory taskParams
    ) external view override onlyAuthorizedCaller(caller) {
        // Decode and validate task parameters
        (string memory taskType, bytes memory taskData) = _decodeTaskParams(taskParams.payload);
        
        // Validate task type
        require(
            keccak256(bytes(taskType)) == keccak256(bytes("restake")) ||
            keccak256(bytes(taskType)) == keccak256(bytes("liquidity")) ||
            keccak256(bytes(taskType)) == keccak256(bytes("rebalance")) ||
            keccak256(bytes(taskType)) == keccak256(bytes("withdraw")),
            "Invalid task type"
        );

        // Validate task data based on type
        if (keccak256(bytes(taskType)) == keccak256(bytes("restake"))) {
            _validateRestakeTask(taskData);
        } else if (keccak256(bytes(taskType)) == keccak256(bytes("liquidity"))) {
            _validateLiquidityTask(taskData);
        } else if (keccak256(bytes(taskType)) == keccak256(bytes("rebalance"))) {
            _validateRebalanceTask(taskData);
        } else if (keccak256(bytes(taskType)) == keccak256(bytes("withdraw"))) {
            _validateWithdrawTask(taskData);
        }
    }

    /**
     * @dev Handle task after creation
     * @param taskHash The task hash
     */
    function handlePostTaskCreation(bytes32 taskHash) external override {
        // Record task creation
        totalTasksCreated++;
        
        emit TaskCreated(taskHash, msg.sender, baseTaskFee, block.timestamp);
    }

    /**
     * @dev Validate task result before submission
     * @param caller The caller address
     * @param taskHash The task hash
     * @param cert The certificate
     * @param result The task result
     */
    function validatePreTaskResultSubmission(
        address caller,
        bytes32 taskHash,
        bytes memory cert,
        bytes memory result
    ) external view override onlyAuthorizedCaller(caller) {
        // Validate certificate
        require(cert.length > 0, "Invalid certificate");
        
        // Validate result
        require(result.length > 0, "Invalid result");
        
        // Additional validation can be added here based on task type
    }

    /**
     * @dev Handle task result after submission
     * @param caller The caller address
     * @param taskHash The task hash
     */
    function handlePostTaskResultSubmission(
        address caller,
        bytes32 taskHash
    ) external override {
        emit TaskResultSubmitted(taskHash, caller, true, block.timestamp);
    }

    /**
     * @dev Calculate task fee
     * @param taskParams The task parameters
     * @return fee The calculated fee
     */
    function calculateTaskFee(
        ITaskMailboxTypes.TaskParams memory taskParams
    ) external view override returns (uint96) {
        (string memory taskType,) = _decodeTaskParams(taskParams.payload);
        
        uint256 taskTypeFee = taskTypeFees[taskType];
        if (taskTypeFee == 0) {
            taskTypeFee = baseTaskFee;
        }
        
        return uint96(taskTypeFee);
    }

    /**
     * @dev Decode task parameters from payload
     * @param payload The task payload
     * @return taskType The task type
     * @return taskData The task data
     */
    function _decodeTaskParams(bytes memory payload) internal pure returns (string memory taskType, bytes memory taskData) {
        // Simple decoding - in production, use proper ABI encoding
        require(payload.length > 0, "Empty payload");
        
        // For now, assume first 32 bytes contain task type length
        uint256 taskTypeLength = uint256(bytes32(payload[0:32]));
        require(taskTypeLength > 0 && taskTypeLength <= payload.length - 32, "Invalid task type length");
        
        taskType = string(payload[32:32 + taskTypeLength]);
        taskData = payload[32 + taskTypeLength:];
    }

    /**
     * @dev Validate restake task data
     * @param taskData The task data
     */
    function _validateRestakeTask(bytes memory taskData) internal pure {
        require(taskData.length > 0, "Empty restake task data");
        // Additional validation can be added here
    }

    /**
     * @dev Validate liquidity task data
     * @param taskData The task data
     */
    function _validateLiquidityTask(bytes memory taskData) internal pure {
        require(taskData.length > 0, "Empty liquidity task data");
        // Additional validation can be added here
    }

    /**
     * @dev Validate rebalance task data
     * @param taskData The task data
     */
    function _validateRebalanceTask(bytes memory taskData) internal pure {
        require(taskData.length > 0, "Empty rebalance task data");
        // Additional validation can be added here
    }

    /**
     * @dev Validate withdraw task data
     * @param taskData The task data
     */
    function _validateWithdrawTask(bytes memory taskData) internal pure {
        require(taskData.length > 0, "Empty withdraw task data");
        // Additional validation can be added here
    }

    /**
     * @dev Get task validation details
     * @param taskHash The task hash
     * @return validation The task validation details
     */
    function getTaskValidation(bytes32 taskHash) external view returns (TaskValidation memory validation) {
        return taskValidations[taskHash];
    }

    /**
     * @dev Get protocol statistics
     * @return totalTasks Total tasks created
     * @return totalFees Total fees collected
     */
    function getProtocolStats() external view returns (uint256 totalTasks, uint256 totalFees) {
        return (totalTasksCreated, totalFeesCollected);
    }

    /**
     * @dev Withdraw collected fees (only owner)
     */
    function withdrawFees() external onlyOwner {
        uint256 amount = address(this).balance;
        require(amount > 0, "No fees to withdraw");
        
        totalFeesCollected += amount;
        payable(owner()).transfer(amount);
    }
}
