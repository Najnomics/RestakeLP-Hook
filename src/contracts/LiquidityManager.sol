// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";

/**
 * @title LiquidityManager
 * @dev Advanced liquidity management contract with yield optimization
 * @notice Handles complex liquidity operations and yield farming strategies
 */
contract LiquidityManager is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    using Math for uint256;

    // Events
    event LiquidityAdded(
        address indexed user,
        address indexed pool,
        uint256 amount0,
        uint256 amount1,
        uint256 liquidity,
        uint256 timestamp
    );

    event LiquidityRemoved(
        address indexed user,
        address indexed pool,
        uint256 amount0,
        uint256 amount1,
        uint256 liquidity,
        uint256 timestamp
    );

    event YieldHarvested(
        address indexed user,
        address indexed pool,
        uint256 yieldAmount,
        address yieldToken,
        uint256 timestamp
    );

    event StrategyUpdated(
        address indexed user,
        address indexed pool,
        string oldStrategy,
        string newStrategy,
        uint256 timestamp
    );

    event PoolAdded(
        address indexed pool,
        address token0,
        address token1,
        uint24 fee,
        uint256 timestamp
    );

    event PoolRemoved(address indexed pool, uint256 timestamp);

    // Structs
    struct PoolInfo {
        address token0;
        address token1;
        uint24 fee;
        bool isActive;
        uint256 totalLiquidity;
        uint256 totalFees;
        uint256 lastUpdateTime;
    }

    struct UserPosition {
        address pool;
        uint256 liquidity;
        uint256 amount0;
        uint256 amount1;
        uint256 timestamp;
        string strategy;
        bool isActive;
        uint256 feesEarned;
    }

    struct YieldStrategy {
        string name;
        address targetPool;
        uint256 minYield;
        uint256 maxSlippage;
        bool isActive;
    }

    // State variables
    mapping(address => PoolInfo) public pools;
    mapping(address => UserPosition[]) public userPositions;
    mapping(address => YieldStrategy) public userStrategies;
    mapping(address => uint256) public userTotalFees;
    mapping(address => mapping(address => uint256)) public userPoolFees;
    
    address[] public poolList;
    uint256 public totalLiquidity;
    uint256 public totalFeesDistributed;
    uint256 public constant MAX_POOLS = 100;
    uint256 public constant MAX_POSITIONS_PER_USER = 50;

    // Modifiers
    modifier onlyValidPool(address pool) {
        require(pools[pool].isActive, "Pool not active");
        _;
    }

    modifier onlyValidPosition(address user, uint256 positionId) {
        require(positionId < userPositions[user].length, "Invalid position ID");
        require(userPositions[user][positionId].isActive, "Position not active");
        _;
    }

    modifier notExceedMaxPositions(address user) {
        require(
            userPositions[user].length < MAX_POSITIONS_PER_USER,
            "Max positions exceeded"
        );
        _;
    }

    constructor() Ownable(msg.sender) {}

    /**
     * @dev Add a new liquidity pool
     */
    function addPool(
        address pool,
        address token0,
        address token1,
        uint24 fee
    ) external onlyOwner {
        require(pool != address(0), "Invalid pool address");
        require(token0 != address(0) && token1 != address(0), "Invalid tokens");
        require(poolList.length < MAX_POOLS, "Max pools exceeded");

        pools[pool] = PoolInfo({
            token0: token0,
            token1: token1,
            fee: fee,
            isActive: true,
            totalLiquidity: 0,
            totalFees: 0,
            lastUpdateTime: block.timestamp
        });

        poolList.push(pool);
        emit PoolAdded(pool, token0, token1, fee, block.timestamp);
    }

    /**
     * @dev Add liquidity to a pool
     */
    function addLiquidity(
        address pool,
        uint256 amount0,
        uint256 amount1,
        string memory strategy
    ) external 
        onlyValidPool(pool)
        notExceedMaxPositions(msg.sender)
        nonReentrant
        returns (uint256 liquidity) {
        
        PoolInfo storage poolInfo = pools[pool];
        
        // Transfer tokens from user
        IERC20(poolInfo.token0).safeTransferFrom(msg.sender, address(this), amount0);
        IERC20(poolInfo.token1).safeTransferFrom(msg.sender, address(this), amount1);

        // Calculate liquidity (simplified calculation)
        liquidity = Math.sqrt(amount0 * amount1);

        // Record user position
        userPositions[msg.sender].push(UserPosition({
            pool: pool,
            liquidity: liquidity,
            amount0: amount0,
            amount1: amount1,
            timestamp: block.timestamp,
            strategy: strategy,
            isActive: true,
            feesEarned: 0
        }));

        // Update pool info
        poolInfo.totalLiquidity += liquidity;
        totalLiquidity += liquidity;

        emit LiquidityAdded(msg.sender, pool, amount0, amount1, liquidity, block.timestamp);
    }

    /**
     * @dev Remove liquidity from a pool
     */
    function removeLiquidity(
        address pool,
        uint256 positionId,
        uint256 liquidityAmount
    ) external 
        onlyValidPool(pool)
        onlyValidPosition(msg.sender, positionId)
        nonReentrant
        returns (uint256 amount0, uint256 amount1) {
        
        UserPosition storage position = userPositions[msg.sender][positionId];
        require(position.pool == pool, "Position pool mismatch");
        require(liquidityAmount <= position.liquidity, "Insufficient liquidity");

        // Calculate proportional amounts
        amount0 = (liquidityAmount * position.amount0) / position.liquidity;
        amount1 = (liquidityAmount * position.amount1) / position.liquidity;

        // Update position
        position.liquidity -= liquidityAmount;
        position.amount0 -= amount0;
        position.amount1 -= amount1;

        // Transfer tokens back to user
        IERC20(pools[pool].token0).safeTransfer(msg.sender, amount0);
        IERC20(pools[pool].token1).safeTransfer(msg.sender, amount1);

        // Update pool info
        pools[pool].totalLiquidity -= liquidityAmount;
        totalLiquidity -= liquidityAmount;

        emit LiquidityRemoved(msg.sender, pool, amount0, amount1, liquidityAmount, block.timestamp);
    }

    /**
     * @dev Harvest yield from a position
     */
    function harvestYield(
        address pool,
        uint256 positionId
    ) external 
        onlyValidPool(pool)
        onlyValidPosition(msg.sender, positionId)
        nonReentrant
        returns (uint256 yieldAmount) {
        
        UserPosition storage position = userPositions[msg.sender][positionId];
        require(position.pool == pool, "Position pool mismatch");

        // Calculate yield (simplified calculation)
        yieldAmount = (position.liquidity * 5) / 1000; // 0.5% yield

        // Update position fees
        position.feesEarned += yieldAmount;
        userTotalFees[msg.sender] += yieldAmount;
        userPoolFees[msg.sender][pool] += yieldAmount;

        // Update pool total fees
        pools[pool].totalFees += yieldAmount;
        totalFeesDistributed += yieldAmount;

        // Transfer yield to user (using token0 as yield token for simplicity)
        IERC20(pools[pool].token0).safeTransfer(msg.sender, yieldAmount);

        emit YieldHarvested(msg.sender, pool, yieldAmount, pools[pool].token0, block.timestamp);
    }

    /**
     * @dev Update user strategy
     */
    function updateStrategy(
        address pool,
        uint256 positionId,
        string memory newStrategy
    ) external 
        onlyValidPool(pool)
        onlyValidPosition(msg.sender, positionId) {
        
        UserPosition storage position = userPositions[msg.sender][positionId];
        require(position.pool == pool, "Position pool mismatch");

        string memory oldStrategy = position.strategy;
        position.strategy = newStrategy;

        emit StrategyUpdated(msg.sender, pool, oldStrategy, newStrategy, block.timestamp);
    }

    /**
     * @dev Set user yield strategy
     */
    function setYieldStrategy(
        string memory name,
        address targetPool,
        uint256 minYield,
        uint256 maxSlippage
    ) external onlyValidPool(targetPool) {
        userStrategies[msg.sender] = YieldStrategy({
            name: name,
            targetPool: targetPool,
            minYield: minYield,
            maxSlippage: maxSlippage,
            isActive: true
        });
    }

    /**
     * @dev Get user positions
     */
    function getUserPositions(address user) external view returns (UserPosition[] memory) {
        return userPositions[user];
    }

    /**
     * @dev Get pool information
     */
    function getPoolInfo(address pool) external view returns (PoolInfo memory) {
        return pools[pool];
    }

    /**
     * @dev Get all pools
     */
    function getAllPools() external view returns (address[] memory) {
        return poolList;
    }

    /**
     * @dev Get user statistics
     */
    function getUserStats(address user) external view returns (
        uint256 totalPositions,
        uint256 userTotalLiquidity,
        uint256 totalFees,
        uint256 activePositions
    ) {
        UserPosition[] memory positions = userPositions[user];
        totalPositions = positions.length;
        userTotalLiquidity = 0;
        activePositions = 0;

        for (uint256 i = 0; i < positions.length; i++) {
            if (positions[i].isActive) {
                userTotalLiquidity += positions[i].liquidity;
                activePositions++;
            }
        }

        totalFees = userTotalFees[user];
    }

    /**
     * @dev Remove pool
     */
    function removePool(address pool) external onlyOwner onlyValidPool(pool) {
        pools[pool].isActive = false;
        emit PoolRemoved(pool, block.timestamp);
    }

    /**
     * @dev Emergency withdraw
     */
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(owner(), amount);
    }
}
