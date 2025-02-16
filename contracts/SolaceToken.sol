// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IBridge.sol";

error InvalidSwapAmount();
error InvalidMirrorAmount();
error FlashLoanNotRepaid();
error BridgeError();

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

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 amount
    ) internal override whenNotPaused {
        super._beforeTokenTransfer(from, to, amount);
    }
}
