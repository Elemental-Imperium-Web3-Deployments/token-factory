// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "../oracles/PriceFeedAggregator.sol";

abstract contract SyntheticTokenBase is ERC20Upgradeable, OwnableUpgradeable, UUPSUpgradeable {
    string public assetType;
    string public underlyingAsset;
    address public oracleAddress;
    
    uint256 public collateralRatio; // in basis points (e.g., 15000 = 150%)
    mapping(address => uint256) public collateralBalances;
    
    event PriceUpdated(uint256 newPrice);
    event AssetTypeSet(string assetType);
    event Minted(address indexed to, uint256 amount, uint256 collateralRequired);
    event Burned(address indexed from, uint256 amount, uint256 collateralReturned);
    
    function initialize(
        string memory name,
        string memory symbol,
        string memory _assetType,
        string memory _underlyingAsset,
        address _oracleAddress
    ) public initializer {
        __ERC20_init(name, symbol);
        __Ownable_init();
        __UUPSUpgradeable_init();
        assetType = _assetType;
        underlyingAsset = _underlyingAsset;
        oracleAddress = _oracleAddress;
    }

    function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

    function setCollateralRatio(uint256 _ratio) external onlyOwner {
        require(_ratio >= 10000, "Ratio must be at least 100%");
        collateralRatio = _ratio;
    }
    
    function mint(uint256 amount) external payable {
        uint256 collateralRequired = calculateCollateralRequired(amount);
        require(msg.value >= collateralRequired, "Insufficient collateral");
        
        collateralBalances[msg.sender] += msg.value;
        _mint(msg.sender, amount);
        
        emit Minted(msg.sender, amount, collateralRequired);
    }
    
    function burn(uint256 amount) external {
        uint256 collateralToReturn = calculateCollateralRequired(amount);
        require(collateralBalances[msg.sender] >= collateralToReturn, "Insufficient collateral");
        
        _burn(msg.sender, amount);
        collateralBalances[msg.sender] -= collateralToReturn;
        payable(msg.sender).transfer(collateralToReturn);
        
        emit Burned(msg.sender, amount, collateralToReturn);
    }
    
    function calculateCollateralRequired(uint256 amount) public view returns (uint256) {
        (uint256 price, uint8 decimals) = PriceFeedAggregator(oracleAddress).getPrice(symbol());
        return (amount * price * collateralRatio) / (10 ** uint256(decimals)) / 10000;
    }
}
