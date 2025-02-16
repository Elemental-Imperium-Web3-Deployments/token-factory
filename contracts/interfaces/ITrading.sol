// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface ITrading {
    event TradeExecuted(
        address indexed trader,
        address indexed tokenIn,
        address indexed tokenOut,
        uint256 amountIn,
        uint256 amountOut
    );

    event BotRegistered(address indexed bot, string botType);
    event BotDeregistered(address indexed bot);

    function executeTrade(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 minAmountOut,
        bytes calldata data
    ) external returns (uint256 amountOut);

    function registerBot(address bot, string calldata botType) external;
    function deregisterBot(address bot) external;
    function isBotRegistered(address bot) external view returns (bool);
    function getBotType(address bot) external view returns (string memory);
}
