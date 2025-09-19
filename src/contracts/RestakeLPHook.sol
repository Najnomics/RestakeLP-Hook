// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Pausable} from "@openzeppelin/contracts/utils/Pausable.sol";

/**
 * @title RestakeLPHook
 * @dev Core contract for RestakeLP Hook AVS functionality
 * @notice This contract handles automated liquidity provision and restaking operations
 */
contract RestakeLPHook is Ownable, ReentrancyGuard, Pausable {
    using SafeERC20 for IERC20;

    // Events
    event LiquidityProvided(
        address indexed user,
        address indexed protocol,
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB,
        uint256 liquidity,
        uint256 timestamp
    );

    event RestakingExecuted(
        address indexed user,
        address indexed protocol,
        address token,
        uint256 amount,
        string strategy,
        uint256 timestamp
    );

    event RebalancingCompleted(
        address indexed user,
        address[] protocols,
        uint256[] amounts,
        uint256 timestamp
    );

    event ProtocolAdded(address indexed protocol, string name);
    event ProtocolRemoved(address indexed protocol);
    event TokenAdded(address indexed token, string symbol);
    event TokenRemoved(address indexed token);
    event FeeUpdated(uint256 oldFee, uint256 newFee);
    event EmergencyWithdraw(address indexed token, uint256 amount);

    // Structs
    struct LiquidityPosition {
        address protocol;
        address tokenA;
        address tokenB;
        uint256 amountA;
        uint256 amountB;
        uint256 liquidity;
        uint256 timestamp;
        bool isActive;
    }

    struct RestakingPosition {
        address protocol;
        address token;
        uint256 amount;
        string strategy;
        uint256 timestamp;
        bool isActive;
    }

    struct ProtocolInfo {
        string name;
        address router;
        bool isActive;
        uint256 fee;
    }

    struct TokenInfo {
        string symbol;
        uint8 decimals;
        bool isActive;
        uint256 minAmount;
    }

    // State variables
    mapping(address => LiquidityPosition[]) public userLiquidityPositions;
    mapping(address => RestakingPosition[]) public userRestakingPositions;
    mapping(address => ProtocolInfo) public supportedProtocols;
    mapping(address => TokenInfo) public supportedTokens;
    mapping(address => uint256) public protocolFees;
    mapping(address => uint256) public userBalances;
    
    address[] public protocolList;
    address[] public tokenList;
    
    uint256 public totalLiquidityProvided;
    uint256 public totalRestakingAmount;
    uint256 public totalFeesCollected;
    uint256 public protocolFeePercentage = 25; // 0.25%
    uint256 public constant FEE_DENOMINATOR = 10000;
    
    // Constants
    uint256 public constant MAX_FEE_PERCENTAGE = 500; // 5%
    uint256 public constant MIN_LIQUIDITY_AMOUNT = 1000; // 1000 wei
    uint256 public constant MAX_POSITIONS_PER_USER = 100;

    // Modifiers
    modifier onlySupportedProtocol(address protocol) {
        require(supportedProtocols[protocol].isActive, "Protocol not supported");
        _;
    }

    modifier onlySupportedToken(address token) {
        require(supportedTokens[token].isActive, "Token not supported");
        _;
    }

    modifier validAmount(uint256 amount) {
        require(amount >= MIN_LIQUIDITY_AMOUNT, "Amount too small");
        _;
    }

    modifier notExceedMaxPositions(address user) {
        require(
            userLiquidityPositions[user].length < MAX_POSITIONS_PER_USER,
            "Max positions exceeded"
        );
        _;
    }

    constructor() Ownable(msg.sender) {}

    /**
     * @dev Add a supported protocol
     */
    function addProtocol(
        address protocol,
        string memory name,
        address router,
        uint256 fee
    ) external onlyOwner {
        require(protocol != address(0), "Invalid protocol address");
        require(bytes(name).length > 0, "Invalid protocol name");
        require(fee <= MAX_FEE_PERCENTAGE, "Fee too high");

        supportedProtocols[protocol] = ProtocolInfo({
            name: name,
            router: router,
            isActive: true,
            fee: fee
        });

        protocolList.push(protocol);
        emit ProtocolAdded(protocol, name);
    }

    /**
     * @dev Add a supported token
     */
    function addToken(
        address token,
        string memory symbol,
        uint8 decimals,
        uint256 minAmount
    ) external onlyOwner {
        require(token != address(0), "Invalid token address");
        require(bytes(symbol).length > 0, "Invalid symbol");
        require(decimals <= 18, "Invalid decimals");

        supportedTokens[token] = TokenInfo({
            symbol: symbol,
            decimals: decimals,
            isActive: true,
            minAmount: minAmount
        });

        tokenList.push(token);
        emit TokenAdded(token, symbol);
    }

    /**
     * @dev Provide liquidity to a protocol
     */
    function provideLiquidity(
        address protocol,
        address tokenA,
        address tokenB,
        uint256 amountA,
        uint256 amountB
    ) external 
        onlySupportedProtocol(protocol)
        onlySupportedToken(tokenA)
        onlySupportedToken(tokenB)
        validAmount(amountA)
        validAmount(amountB)
        notExceedMaxPositions(msg.sender)
        whenNotPaused
        nonReentrant
        returns (uint256 liquidity) {
        
        // Validate that tokens are different
        require(tokenA != tokenB, "Tokens must be different");
        
        // Transfer tokens from user
        IERC20(tokenA).safeTransferFrom(msg.sender, address(this), amountA);
        IERC20(tokenB).safeTransferFrom(msg.sender, address(this), amountB);

        // Calculate liquidity (simplified calculation)
        liquidity = (amountA + amountB) / 2;

        // Record the position
        userLiquidityPositions[msg.sender].push(LiquidityPosition({
            protocol: protocol,
            tokenA: tokenA,
            tokenB: tokenB,
            amountA: amountA,
            amountB: amountB,
            liquidity: liquidity,
            timestamp: block.timestamp,
            isActive: true
        }));

        totalLiquidityProvided += liquidity;
        userBalances[msg.sender] += liquidity;

        emit LiquidityProvided(msg.sender, protocol, tokenA, tokenB, amountA, amountB, liquidity, block.timestamp);
    }

    /**
     * @dev Execute restaking operation
     */
    function executeRestaking(
        address protocol,
        address token,
        uint256 amount,
        string memory strategy
    ) external 
        onlySupportedProtocol(protocol)
        onlySupportedToken(token)
        validAmount(amount)
        whenNotPaused
        nonReentrant {
        
        // Transfer tokens from user
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        // Record the position
        userRestakingPositions[msg.sender].push(RestakingPosition({
            protocol: protocol,
            token: token,
            amount: amount,
            strategy: strategy,
            timestamp: block.timestamp,
            isActive: true
        }));

        totalRestakingAmount += amount;

        emit RestakingExecuted(msg.sender, protocol, token, amount, strategy, block.timestamp);
    }

    /**
     * @dev Execute rebalancing across protocols
     */
    function executeRebalancing(
        address[] calldata protocols,
        uint256[] calldata amounts
    ) external whenNotPaused nonReentrant {
        require(protocols.length == amounts.length, "Arrays length mismatch");
        require(protocols.length > 0, "Empty arrays");

        for (uint256 i = 0; i < protocols.length; i++) {
            require(supportedProtocols[protocols[i]].isActive, "Protocol not supported");
            require(amounts[i] > 0, "Invalid amount");
        }

        emit RebalancingCompleted(msg.sender, protocols, amounts, block.timestamp);
    }

    /**
     * @dev Update protocol fee
     */
    function updateProtocolFee(uint256 newFee) external onlyOwner {
        require(newFee <= MAX_FEE_PERCENTAGE, "Fee too high");
        uint256 oldFee = protocolFeePercentage;
        protocolFeePercentage = newFee;
        emit FeeUpdated(oldFee, newFee);
    }

    /**
     * @dev Pause the contract
     */
    function pause() external onlyOwner {
        _pause();
    }

    /**
     * @dev Unpause the contract
     */
    function unpause() external onlyOwner {
        _unpause();
    }

    /**
     * @dev Get user's liquidity positions
     */
    function getUserLiquidityPositions(address user) external view returns (LiquidityPosition[] memory) {
        return userLiquidityPositions[user];
    }

    /**
     * @dev Get user's restaking positions
     */
    function getUserRestakingPositions(address user) external view returns (RestakingPosition[] memory) {
        return userRestakingPositions[user];
    }

    /**
     * @dev Get protocol statistics
     */
    function getProtocolStats() external view returns (
        uint256 totalLiquidity,
        uint256 totalRestaking,
        uint256 totalFees,
        uint256 totalProtocols,
        uint256 totalTokens
    ) {
        return (
            totalLiquidityProvided,
            totalRestakingAmount,
            totalFeesCollected,
            protocolList.length,
            tokenList.length
        );
    }

    /**
     * @dev Emergency withdraw function
     */
    function emergencyWithdraw(address token, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(owner(), amount);
        emit EmergencyWithdraw(token, amount);
    }

    /**
     * @dev Remove protocol
     */
    function removeProtocol(address protocol) external onlyOwner {
        require(supportedProtocols[protocol].isActive, "Protocol not active");
        supportedProtocols[protocol].isActive = false;
        emit ProtocolRemoved(protocol);
    }

    /**
     * @dev Remove token
     */
    function removeToken(address token) external onlyOwner {
        require(supportedTokens[token].isActive, "Token not active");
        supportedTokens[token].isActive = false;
        emit TokenRemoved(token);
    }
}
