// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IFlashLoanReceiver {
    function executeOperation(uint256 amount, bytes calldata data) external returns (bool);
}
