// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IDApp {
    event DAppRegistered(address indexed dapp, string dappType, string metadata);
    event DAppDeregistered(address indexed dapp);
    event DAppInteraction(address indexed dapp, address indexed user, bytes data);

    function registerDApp(
        string calldata dappType,
        string calldata metadata
    ) external returns (bool);

    function deregisterDApp() external returns (bool);
    function isDAppRegistered(address dapp) external view returns (bool);
    function getDAppMetadata(address dapp) external view returns (string memory dappType, string memory metadata);
    function interactWithDApp(address dapp, bytes calldata data) external returns (bytes memory);
}
