// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.27;

import {IAllocationManager} from "@eigenlayer-contracts/src/contracts/interfaces/IAllocationManager.sol";
import {IKeyRegistrar} from "@eigenlayer-contracts/src/contracts/interfaces/IKeyRegistrar.sol";
import {IPermissionController} from "@eigenlayer-contracts/src/contracts/interfaces/IPermissionController.sol";
import {TaskAVSRegistrarBase} from "@eigenlayer-middleware/src/avs/task/TaskAVSRegistrarBase.sol";

/**
 * @title RestakeLPRegistrar
 * @dev L1 registrar for RestakeLP Hook AVS operators
 * @notice This contract manages operator registration and configuration for the RestakeLP Hook AVS
 */
contract RestakeLPRegistrar is TaskAVSRegistrarBase {
    // Events
    event OperatorRegistered(
        address indexed operator,
        string metadataURI,
        uint256 timestamp
    );

    event OperatorDeregistered(
        address indexed operator,
        uint256 timestamp
    );

    event RestakingStrategyUpdated(
        address indexed operator,
        string oldStrategy,
        string newStrategy
    );

    event LiquidityThresholdUpdated(
        address indexed operator,
        uint256 oldThreshold,
        uint256 newThreshold
    );

    // Structs
    struct OperatorConfig {
        string restakingStrategy;
        uint256 liquidityThreshold;
        bool isActive;
        uint256 registrationTime;
    }

    // State variables
    mapping(address => OperatorConfig) public operatorConfigs;
    mapping(address => bool) public registeredOperators;
    address[] public operatorList;

    // Constants
    uint256 public constant MIN_LIQUIDITY_THRESHOLD = 1000 * 10**18; // 1000 tokens minimum
    uint256 public constant MAX_LIQUIDITY_THRESHOLD = 1000000 * 10**18; // 1M tokens maximum

    // Modifiers
    modifier onlyRegisteredOperator(address operator) {
        require(registeredOperators[operator], "Operator not registered");
        _;
    }

    modifier validLiquidityThreshold(uint256 threshold) {
        require(threshold >= MIN_LIQUIDITY_THRESHOLD && threshold <= MAX_LIQUIDITY_THRESHOLD, "Invalid liquidity threshold");
        _;
    }

    /**
     * @dev Constructor that passes parameters to parent TaskAVSRegistrarBase
     * @param _allocationManager The AllocationManager contract address
     * @param _keyRegistrar The KeyRegistrar contract address
     * @param _permissionController The PermissionController contract address
     */
    constructor(
        IAllocationManager _allocationManager,
        IKeyRegistrar _keyRegistrar,
        IPermissionController _permissionController
    ) TaskAVSRegistrarBase(_allocationManager, _keyRegistrar, _permissionController) {}

    /**
     * @dev Initializer that calls parent initializer
     * @param _avs The address of the AVS
     * @param _owner The owner of the contract
     * @param _initialConfig The initial AVS configuration
     */
    function initialize(address _avs, address _owner, AvsConfig memory _initialConfig) external initializer {
        __TaskAVSRegistrarBase_init(_avs, _owner, _initialConfig);
    }

    /**
     * @dev Register a new operator for RestakeLP operations
     * @param operator The operator address to register
     * @param metadataURI URI containing operator metadata
     * @param restakingStrategy The restaking strategy to use
     * @param liquidityThreshold The minimum liquidity threshold for operations
     */
    function registerOperator(
        address operator,
        string memory metadataURI,
        string memory restakingStrategy,
        uint256 liquidityThreshold
    ) external onlyOwner validLiquidityThreshold(liquidityThreshold) {
        require(!registeredOperators[operator], "Operator already registered");
        require(bytes(restakingStrategy).length > 0, "Invalid restaking strategy");

        registeredOperators[operator] = true;
        operatorList.push(operator);
        
        operatorConfigs[operator] = OperatorConfig({
            restakingStrategy: restakingStrategy,
            liquidityThreshold: liquidityThreshold,
            isActive: true,
            registrationTime: block.timestamp
        });

        emit OperatorRegistered(operator, metadataURI, block.timestamp);
    }

    /**
     * @dev Deregister an operator
     * @param operator The operator address to deregister
     */
    function deregisterOperator(address operator) external onlyOwner onlyRegisteredOperator(operator) {
        registeredOperators[operator] = false;
        operatorConfigs[operator].isActive = false;

        // Remove from operator list
        for (uint256 i = 0; i < operatorList.length; i++) {
            if (operatorList[i] == operator) {
                operatorList[i] = operatorList[operatorList.length - 1];
                operatorList.pop();
                break;
            }
        }

        emit OperatorDeregistered(operator, block.timestamp);
    }

    /**
     * @dev Update operator's restaking strategy
     * @param operator The operator address
     * @param newStrategy The new restaking strategy
     */
    function updateRestakingStrategy(
        address operator,
        string memory newStrategy
    ) external onlyOwner onlyRegisteredOperator(operator) {
        require(bytes(newStrategy).length > 0, "Invalid restaking strategy");
        
        string memory oldStrategy = operatorConfigs[operator].restakingStrategy;
        operatorConfigs[operator].restakingStrategy = newStrategy;

        emit RestakingStrategyUpdated(operator, oldStrategy, newStrategy);
    }

    /**
     * @dev Update operator's liquidity threshold
     * @param operator The operator address
     * @param newThreshold The new liquidity threshold
     */
    function updateLiquidityThreshold(
        address operator,
        uint256 newThreshold
    ) external onlyOwner onlyRegisteredOperator(operator) validLiquidityThreshold(newThreshold) {
        uint256 oldThreshold = operatorConfigs[operator].liquidityThreshold;
        operatorConfigs[operator].liquidityThreshold = newThreshold;

        emit LiquidityThresholdUpdated(operator, oldThreshold, newThreshold);
    }

    /**
     * @dev Get operator configuration
     * @param operator The operator address
     * @return config The operator configuration
     */
    function getOperatorConfig(address operator) external view returns (OperatorConfig memory config) {
        require(registeredOperators[operator], "Operator not registered");
        return operatorConfigs[operator];
    }

    /**
     * @dev Get all registered operators
     * @return operators Array of registered operator addresses
     */
    function getAllOperators() external view returns (address[] memory operators) {
        return operatorList;
    }

    /**
     * @dev Get active operators count
     * @return count Number of active operators
     */
    function getActiveOperatorsCount() external view returns (uint256 count) {
        uint256 activeCount = 0;
        for (uint256 i = 0; i < operatorList.length; i++) {
            if (operatorConfigs[operatorList[i]].isActive) {
                activeCount++;
            }
        }
        return activeCount;
    }

    /**
     * @dev Check if operator is registered and active
     * @param operator The operator address
     * @return isActive True if operator is registered and active
     */
    function isOperatorActive(address operator) external view returns (bool isActive) {
        return registeredOperators[operator] && operatorConfigs[operator].isActive;
    }
}
