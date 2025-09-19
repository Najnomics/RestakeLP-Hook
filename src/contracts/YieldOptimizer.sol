// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title YieldOptimizer
 * @dev Advanced yield optimization contract for RestakeLP Hook
 * @notice Implements sophisticated yield farming and optimization strategies
 */
contract YieldOptimizer is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Math for uint256;

    // Events
    event StrategyExecuted(
        address indexed user,
        string strategyName,
        address[] protocols,
        uint256[] amounts,
        uint256 expectedYield,
        uint256 actualYield,
        uint256 timestamp
    );

    event RebalancingTriggered(
        address indexed user,
        address[] fromProtocols,
        address[] toProtocols,
        uint256[] amounts,
        uint256 timestamp
    );

    event YieldClaimed(
        address indexed user,
        address protocol,
        uint256 amount,
        address token,
        uint256 timestamp
    );

    event StrategyAdded(
        string name,
        address[] protocols,
        uint256[] weights,
        uint256 minYield,
        bool isActive
    );

    event StrategyRemoved(string name, uint256 timestamp);

    // Structs
    struct YieldStrategy {
        string name;
        address[] protocols;
        uint256[] weights;
        uint256 minYield;
        uint256 maxSlippage;
        bool isActive;
        uint256 totalDeposited;
        uint256 totalYield;
        uint256 lastExecution;
    }

    struct UserAllocation {
        address protocol;
        uint256 amount;
        uint256 weight;
        uint256 yieldEarned;
        uint256 lastUpdate;
    }

    struct ProtocolYield {
        address protocol;
        uint256 apy;
        uint256 liquidity;
        uint256 fees;
        bool isActive;
    }

    // State variables
    mapping(string => YieldStrategy) public strategies;
    mapping(address => UserAllocation[]) public userAllocations;
    mapping(address => ProtocolYield) public protocolYields;
    mapping(address => uint256) public userTotalYield;
    mapping(address => mapping(address => uint256)) public userProtocolYield;
    
    string[] public strategyNames;
    address[] public supportedProtocols;
    uint256 public totalYieldDistributed;
    uint256 public constant MAX_STRATEGIES = 50;
    uint256 public constant MAX_PROTOCOLS_PER_STRATEGY = 10;
    uint256 public constant YIELD_PRECISION = 1e18;

    // Modifiers
    modifier onlyValidStrategy(string memory strategyName) {
        require(strategies[strategyName].isActive, "Strategy not active");
        _;
    }

    modifier onlyValidProtocol(address protocol) {
        require(protocolYields[protocol].isActive, "Protocol not active");
        _;
    }

    constructor() Ownable(msg.sender) {}

    /**
     * @dev Add a new yield strategy
     */
    function addStrategy(
        string memory name,
        address[] memory protocols,
        uint256[] memory weights,
        uint256 minYield,
        uint256 maxSlippage
    ) external onlyOwner {
        require(bytes(name).length > 0, "Invalid strategy name");
        require(protocols.length == weights.length, "Arrays length mismatch");
        require(protocols.length <= MAX_PROTOCOLS_PER_STRATEGY, "Too many protocols");
        require(strategyNames.length < MAX_STRATEGIES, "Max strategies exceeded");

        uint256 totalWeight = 0;
        for (uint256 i = 0; i < weights.length; i++) {
            totalWeight += weights[i];
            require(protocolYields[protocols[i]].isActive, "Protocol not active");
        }
        require(totalWeight == 10000, "Weights must sum to 10000");

        strategies[name] = YieldStrategy({
            name: name,
            protocols: protocols,
            weights: weights,
            minYield: minYield,
            maxSlippage: maxSlippage,
            isActive: true,
            totalDeposited: 0,
            totalYield: 0,
            lastExecution: 0
        });

        strategyNames.push(name);
        emit StrategyAdded(name, protocols, weights, minYield, true);
    }

    /**
     * @dev Add a supported protocol
     */
    function addProtocol(
        address protocol,
        uint256 apy,
        uint256 liquidity
    ) external onlyOwner {
        require(protocol != address(0), "Invalid protocol address");
        require(apy <= 10000, "APY too high"); // Max 100%

        protocolYields[protocol] = ProtocolYield({
            protocol: protocol,
            apy: apy,
            liquidity: liquidity,
            fees: 0,
            isActive: true
        });

        supportedProtocols.push(protocol);
    }

    /**
     * @dev Execute a yield strategy
     */
    function executeStrategy(
        string memory strategyName,
        uint256 totalAmount
    ) external 
        onlyValidStrategy(strategyName)
        nonReentrant
        returns (uint256 actualYield) {
        
        YieldStrategy storage strategy = strategies[strategyName];
        require(totalAmount > 0, "Invalid amount");

        // Calculate allocations based on weights
        uint256[] memory amounts = new uint256[](strategy.protocols.length);
        for (uint256 i = 0; i < strategy.protocols.length; i++) {
            amounts[i] = (totalAmount * strategy.weights[i]) / 10000;
        }

        // Execute allocations
        uint256 totalYield = 0;
        for (uint256 i = 0; i < strategy.protocols.length; i++) {
            uint256 yield = _executeAllocation(
                strategy.protocols[i],
                amounts[i],
                strategy.maxSlippage
            );
            totalYield += yield;
        }

        // Update strategy stats
        strategy.totalDeposited += totalAmount;
        strategy.totalYield += totalYield;
        strategy.lastExecution = block.timestamp;

        // Update user allocations
        _updateUserAllocations(msg.sender, strategy.protocols, amounts, totalYield);

        actualYield = totalYield;
        totalYieldDistributed += totalYield;

        emit StrategyExecuted(
            msg.sender,
            strategyName,
            strategy.protocols,
            amounts,
            strategy.minYield,
            actualYield,
            block.timestamp
        );
    }

    /**
     * @dev Trigger rebalancing for a user
     */
    function triggerRebalancing(
        address[] memory fromProtocols,
        address[] memory toProtocols,
        uint256[] memory amounts
    ) external nonReentrant {
        require(fromProtocols.length == amounts.length, "Arrays length mismatch");
        require(toProtocols.length > 0, "No target protocols");

        // Execute rebalancing logic
        for (uint256 i = 0; i < fromProtocols.length; i++) {
            require(protocolYields[fromProtocols[i]].isActive, "Source protocol not active");
            require(amounts[i] > 0, "Invalid amount");
        }

        for (uint256 i = 0; i < toProtocols.length; i++) {
            require(protocolYields[toProtocols[i]].isActive, "Target protocol not active");
        }

        emit RebalancingTriggered(msg.sender, fromProtocols, toProtocols, amounts, block.timestamp);
    }

    /**
     * @dev Claim yield from a specific protocol
     */
    function claimYield(address protocol) external 
        onlyValidProtocol(protocol)
        nonReentrant
        returns (uint256 yieldAmount) {
        
        yieldAmount = userProtocolYield[msg.sender][protocol];
        require(yieldAmount > 0, "No yield to claim");

        // Reset user protocol yield
        userProtocolYield[msg.sender][protocol] = 0;
        userTotalYield[msg.sender] -= yieldAmount;

        // Transfer yield to user (simplified - using ETH as yield token)
        payable(msg.sender).transfer(yieldAmount);

        emit YieldClaimed(msg.sender, protocol, yieldAmount, address(0), block.timestamp);
    }

    /**
     * @dev Get user allocations
     */
    function getUserAllocations(address user) external view returns (UserAllocation[] memory) {
        return userAllocations[user];
    }

    /**
     * @dev Get strategy information
     */
    function getStrategy(string memory name) external view returns (YieldStrategy memory) {
        return strategies[name];
    }

    /**
     * @dev Get all strategies
     */
    function getAllStrategies() external view returns (string[] memory) {
        return strategyNames;
    }

    /**
     * @dev Get protocol yield information
     */
    function getProtocolYield(address protocol) external view returns (ProtocolYield memory) {
        return protocolYields[protocol];
    }

    /**
     * @dev Get user yield statistics
     */
    function getUserYieldStats(address user) external view returns (
        uint256 totalYield,
        uint256 totalAllocations,
        uint256 activeProtocols
    ) {
        totalYield = userTotalYield[user];
        UserAllocation[] memory allocations = userAllocations[user];
        totalAllocations = allocations.length;
        activeProtocols = 0;

        for (uint256 i = 0; i < allocations.length; i++) {
            if (allocations[i].amount > 0) {
                activeProtocols++;
            }
        }
    }

    /**
     * @dev Internal function to execute allocation
     */
    function _executeAllocation(
        address protocol,
        uint256 amount,
        uint256 /* maxSlippage */
    ) internal returns (uint256 yield) {
        // Simplified yield calculation based on protocol APY
        uint256 apy = protocolYields[protocol].apy;
        yield = (amount * apy) / (10000 * 365); // Daily yield
        
        // Update protocol stats
        protocolYields[protocol].liquidity += amount;
        protocolYields[protocol].fees += yield;
    }

    /**
     * @dev Internal function to update user allocations
     */
    function _updateUserAllocations(
        address user,
        address[] memory protocols,
        uint256[] memory amounts,
        uint256 totalYield
    ) internal {
        // Clear existing allocations
        delete userAllocations[user];

        // Add new allocations
        for (uint256 i = 0; i < protocols.length; i++) {
            userAllocations[user].push(UserAllocation({
                protocol: protocols[i],
                amount: amounts[i],
                weight: 0, // Will be calculated
                yieldEarned: (totalYield * amounts[i]) / _getTotalAmount(amounts),
                lastUpdate: block.timestamp
            }));

            // Update user protocol yield
            userProtocolYield[user][protocols[i]] += (totalYield * amounts[i]) / _getTotalAmount(amounts);
        }

        userTotalYield[user] += totalYield;
    }

    /**
     * @dev Internal function to get total amount
     */
    function _getTotalAmount(uint256[] memory amounts) internal pure returns (uint256 total) {
        for (uint256 i = 0; i < amounts.length; i++) {
            total += amounts[i];
        }
    }

    /**
     * @dev Remove strategy
     */
    function removeStrategy(string memory name) external onlyOwner onlyValidStrategy(name) {
        strategies[name].isActive = false;
        emit StrategyRemoved(name, block.timestamp);
    }

    /**
     * @dev Remove protocol
     */
    function removeProtocol(address protocol) external onlyOwner onlyValidProtocol(protocol) {
        protocolYields[protocol].isActive = false;
    }

    /**
     * @dev Emergency withdraw
     */
    function emergencyWithdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    // Receive function to accept ETH
    receive() external payable {}
}
