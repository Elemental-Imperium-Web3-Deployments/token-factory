// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract CrossChainBridge is PausableUpgradeable, AccessControlUpgradeable {
    bytes32 public constant BRIDGE_ROLE = keccak256("BRIDGE_ROLE");
    
    struct BridgeRequest {
        address token;
        address sender;
        address recipient;
        uint256 amount;
        uint256 targetChainId;
        bool processed;
    }

    mapping(bytes32 => BridgeRequest) public bridgeRequests;
    mapping(uint256 => bool) public supportedChainIds;

    event BridgeInitiated(
        bytes32 indexed requestId,
        address token,
        address sender,
        address recipient,
        uint256 amount,
        uint256 targetChainId
    );

    function initialize() public initializer {
        __Pausable_init();
        __AccessControl_init();
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(BRIDGE_ROLE, msg.sender);
    }

    function initiateBridge(
        address token,
        address recipient,
        uint256 amount,
        uint256 targetChainId
    ) external whenNotPaused returns (bytes32) {
        require(supportedChainIds[targetChainId], "Unsupported chain");
        
        bytes32 requestId = keccak256(
            abi.encodePacked(
                token,
                msg.sender,
                recipient,
                amount,
                targetChainId,
                block.timestamp
            )
        );

        IERC20(token).transferFrom(msg.sender, address(this), amount);

        bridgeRequests[requestId] = BridgeRequest({
            token: token,
            sender: msg.sender,
            recipient: recipient,
            amount: amount,
            targetChainId: targetChainId,
            processed: false
        });

        emit BridgeInitiated(
            requestId,
            token,
            msg.sender,
            recipient,
            amount,
            targetChainId
        );

        return requestId;
    }

    function addSupportedChain(uint256 chainId) external onlyRole(BRIDGE_ROLE) {
        supportedChainIds[chainId] = true;
    }

    function pause() external onlyRole(BRIDGE_ROLE) {
        _pause();
    }

    function unpause() external onlyRole(BRIDGE_ROLE) {
        _unpause();
    }
}
