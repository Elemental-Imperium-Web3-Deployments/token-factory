// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "../tokens/SyntheticTokenBase.sol";
import "../tokens/SyntheticTokenImplementation.sol";

contract SyntheticTokenFactory is UUPSUpgradeable {
    enum TokenCategory { 
        FIAT, 
        COMMODITY, 
        EQUITY, 
        CRYPTO, 
        REAL_ESTATE, 
        BOND, 
        METAVERSE 
    }

    mapping(TokenCategory => address[]) public tokensByCategory;
    mapping(string => address) public tokensBySymbol;
    
    event TokenDeployed(
        address tokenAddress,
        string symbol,
        TokenCategory category
    );

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() {
        _disableInitializers();
    }

    function initialize() public initializer {
        __UUPSUpgradeable_init();
    }

    function deployToken(
        string memory name,
        string memory symbol,
        TokenCategory category,
        string memory underlyingAsset,
        address oracleAddress
    ) external returns (address) {
        require(tokensBySymbol[symbol] == address(0), "Token already exists");
        
        string memory assetType = getCategoryString(category);
        
        // Deploy token implementation
        SyntheticTokenImplementation tokenImpl = new SyntheticTokenImplementation();
        
        // Deploy proxy
        bytes memory initData = abi.encodeWithSelector(
            SyntheticTokenBase.initialize.selector,
            name,
            symbol,
            assetType,
            underlyingAsset,
            oracleAddress
        );
        
        ERC1967Proxy proxy = new ERC1967Proxy(
            address(tokenImpl),
            initData
        );
        
        address tokenAddress = address(proxy);
        tokensByCategory[category].push(tokenAddress);
        tokensBySymbol[symbol] = tokenAddress;
        
        emit TokenDeployed(tokenAddress, symbol, category);
        return tokenAddress;
    }

    function getCategoryString(TokenCategory category) internal pure returns (string memory) {
        if (category == TokenCategory.FIAT) return "Fiat";
        if (category == TokenCategory.COMMODITY) return "Commodity";
        if (category == TokenCategory.EQUITY) return "Equity";
        if (category == TokenCategory.CRYPTO) return "Crypto";
        if (category == TokenCategory.REAL_ESTATE) return "RealEstate";
        if (category == TokenCategory.BOND) return "Bond";
        if (category == TokenCategory.METAVERSE) return "Metaverse";
        revert("Invalid category");
    }

    function _authorizeUpgrade(address) internal override {}
}
