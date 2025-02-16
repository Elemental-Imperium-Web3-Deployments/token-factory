// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IBridge {
    event TokensBridged(address indexed from, uint256 amount, uint256 targetChainId);
    event TokensReceived(address indexed to, uint256 amount, uint256 sourceChainId);
    
    function bridgeTokens(uint256 amount, uint256 targetChainId) external;
    function receiveBridgedTokens(address to, uint256 amount, uint256 sourceChainId, bytes calldata proof) external;
}
