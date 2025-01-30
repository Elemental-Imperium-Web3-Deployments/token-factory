// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract PriceFeedAggregator is Ownable {
    mapping(string => address) public priceFeeds;
    mapping(string => uint8) public decimals;
    
    event PriceFeedUpdated(string symbol, address feed);
    
    function setPriceFeed(string memory symbol, address feed) external onlyOwner {
        require(feed != address(0), "Invalid feed address");
        priceFeeds[symbol] = feed;
        decimals[symbol] = AggregatorV3Interface(feed).decimals();
        emit PriceFeedUpdated(symbol, feed);
    }
    
    function getPrice(string memory symbol) external view returns (uint256, uint8) {
        address feed = priceFeeds[symbol];
        require(feed != address(0), "Price feed not found");
        
        (, int256 price,,,) = AggregatorV3Interface(feed).latestRoundData();
        require(price > 0, "Invalid price");
        
        return (uint256(price), decimals[symbol]);
    }
}
