// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IBridge.sol";
import "./interfaces/ITrading.sol";
import "./interfaces/IDApp.sol";

error InvalidSwapAmount();
error InvalidMirrorAmount();
error FlashLoanNotRepaid();
error BridgeError();
error UnauthorizedBot();
error DAppNotRegistered();

contract SolaceToken is ERC20, ERC20Burnable, AccessControl, Pausable, ReentrancyGuard, IBridge, ITrading, IDApp {
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MIRROR_ROLE = keccak256("MIRROR_ROLE");

    uint256 public constant FLASH_LOAN_FEE = 9; // 0.09% fee
    mapping(address => uint256) public mirroredBalances;
    mapping(bytes32 => bool) public executedBridgeTransactions;

    event SwapExecuted(address indexed from, address indexed to, uint256 amount);
    event MirrorCreated(address indexed owner, uint256 amount);
    event FlashLoan(address indexed receiver, uint256 amount);

    constructor() ERC20("Solace", "SLT") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
        _grantRole(BRIDGE_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MIRROR_ROLE, msg.sender);
    }

    function mint(address to, uint256 amount) public onlyRole(MINTER_ROLE) {
        _mint(to, amount);
    }

    function swap(address to, uint256 amount) external nonReentrant {
        if (amount == 0) revert InvalidSwapAmount();
        _transfer(msg.sender, to, amount);
        emit SwapExecuted(msg.sender, to, amount);
    }

    function createMirror(uint256 amount) external nonReentrant {
        if (amount == 0) revert InvalidMirrorAmount();
        _burn(msg.sender, amount);
        mirroredBalances[msg.sender] += amount;
        emit MirrorCreated(msg.sender, amount);
    }

    function redeemMirror(uint256 amount) external nonReentrant {
        if (amount == 0 || mirroredBalances[msg.sender] < amount) revert InvalidMirrorAmount();
        mirroredBalances[msg.sender] -= amount;
        _mint(msg.sender, amount);
    }

    function bridgeTokens(uint256 amount, uint256 targetChainId) external override nonReentrant {
        _burn(msg.sender, amount);
        emit TokensBridged(msg.sender, amount, targetChainId);
    }

    function receiveBridgedTokens(
        address to,
        uint256 amount,
        uint256 sourceChainId,
        bytes calldata proof
    ) external override onlyRole(BRIDGE_ROLE) nonReentrant {
        bytes32 txHash = keccak256(abi.encodePacked(to, amount, sourceChainId, proof));
        if (executedBridgeTransactions[txHash]) revert BridgeError();
        
        executedBridgeTransactions[txHash] = true;
        _mint(to, amount);
        emit TokensReceived(to, amount, sourceChainId);
    }

    function flashLoan(
        address receiver,
        uint256 amount,
        bytes calldata data
    ) external nonReentrant {
        uint256 balanceBefore = balanceOf(address(this));
        _mint(receiver, amount);
        
        require(
            receiver.code.length > 0,
            "Flash loan receiver must be a contract"
        );
        
        (bool success,) = receiver.call(
            abi.encodeWithSignature(
                "executeOperation(uint256,bytes)",
                amount,
                data
            )
        );
        require(success, "Flash loan operation failed");

        uint256 balanceAfter = balanceOf(address(this));
        uint256 fee = (amount * FLASH_LOAN_FEE) / 10000;
        
        if (balanceAfter < balanceBefore + fee) revert FlashLoanNotRepaid();
        
        emit FlashLoan(receiver, amount);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    // Trading Bot Interface Implementation
    mapping(address => string) private botTypes;
    mapping(address => bool) private registeredBots;

    function registerBot(address bot, string calldata botType) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        registeredBots[bot] = true;
        botTypes[bot] = botType;
        emit BotRegistered(bot, botType);
    }

    function deregisterBot(address bot) external override onlyRole(DEFAULT_ADMIN_ROLE) {
        registeredBots[bot] = false;
        emit BotDeregistered(bot);
    }

    function isBotRegistered(address bot) external view override returns (bool) {
        return registeredBots[bot];
    }

    function getBotType(address bot) external view override returns (string memory) {
        return botTypes[bot];
    }

    function executeTrade(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        bytes calldata data
    ) external override returns (uint256 amountOut) {
        require(registeredBots[msg.sender] || hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Unauthorized");
        // Implementation for specific trading logic
        amountOut = minAmountOut; // Placeholder, actual implementation would include DEX integration
        emit TradeExecuted(msg.sender, tokenIn, tokenOut, amountIn, amountOut);
        return amountOut;
    }

    // DApp Interface Implementation
    mapping(address => string) private dappTypes;
    mapping(address => string) private dappMetadata;
    mapping(address => bool) private registeredDApps;

    function registerDApp(
        string calldata dappType,
        string calldata metadata
    ) external override returns (bool) {
        registeredDApps[msg.sender] = true;
        dappTypes[msg.sender] = dappType;
        dappMetadata[msg.sender] = metadata;
        emit DAppRegistered(msg.sender, dappType, metadata);
        return true;
    }

    function deregisterDApp() external override returns (bool) {
        registeredDApps[msg.sender] = false;
        emit DAppDeregistered(msg.sender);
        return true;
    }

    function isDAppRegistered(address dapp) external view override returns (bool) {
        return registeredDApps[dapp];
    }

    function getDAppMetadata(address dapp) external view override returns (
        string memory dappType,
        string memory metadata
    ) {
        return (dappTypes[dapp], dappMetadata[dapp]);
    }

    function interactWithDApp(
        address dapp,
        bytes calldata data
    ) external override returns (bytes memory) {
        require(registeredDApps[dapp], "DApp not registered");
        emit DAppInteraction(dapp, msg.sender, data);
        return data; // Placeholder, actual implementation would process the interaction
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}
