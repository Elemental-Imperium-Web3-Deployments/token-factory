// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "../interfaces/IFlashLoanReceiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockFlashLoanReceiver is IFlashLoanReceiver {
    IERC20 public immutable TOKEN;
    bool public shouldRepay;

    constructor(address token) {
        TOKEN = IERC20(token);
        shouldRepay = true;
    }

    function setShouldRepay(bool _shouldRepay) external {
        shouldRepay = _shouldRepay;
    }

    function executeOperation(
        uint256 amount,
        bytes calldata
    ) external override returns (bool) {
        if (shouldRepay) {
            uint256 fee = (amount * 9) / 10000; // 0.09% fee
            TOKEN.transfer(msg.sender, amount + fee);
            return true;
        }
        return false;
    }
}
