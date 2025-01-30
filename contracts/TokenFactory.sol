// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

contract TokenFactory is Initializable, AccessControlUpgradeable, PausableUpgradeable {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    mapping(address => bool) public tokens;
    uint256 public tokenCount;

    event TokenCreated(address indexed tokenAddress, string name, string symbol);

    function initialize() public initializer {
        __AccessControl_init();
        __Pausable_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(ADMIN_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function createToken(
        string memory name,
        string memory symbol,
        uint256 initialSupply
    ) external onlyRole(MINTER_ROLE) returns (address) {
        CustomToken token = new CustomToken(name, symbol, initialSupply, msg.sender);
        tokens[address(token)] = true;
        tokenCount++;
        emit TokenCreated(address(token), name, symbol);
        return address(token);
    }

    function pause() external onlyRole(ADMIN_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(ADMIN_ROLE) {
        _unpause();
    }
}

contract CustomToken is ERC20Upgradeable {
    constructor(
        string memory name,
        string memory symbol,
        uint256 initialSupply,
        address owner
    ) {
        _initialize(name, symbol);
        _mint(owner, initialSupply);
    }

    function _initialize(string memory name, string memory symbol) internal initializer {
        __ERC20_init(name, symbol);
    }
}
