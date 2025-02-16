import { ethers } from "hardhat";

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    const SolaceToken = await ethers.getContractFactory("SolaceToken");
    const token = await SolaceToken.deploy();
    await token.deployed();

    console.log("SolaceToken deployed to:", token.address);

    // Mint initial supply (100,000 ETH worth)
    const initialSupply = ethers.utils.parseEther("100000");
    await token.mint(deployer.address, initialSupply);
    
    console.log("Initial supply minted:", ethers.utils.formatEther(initialSupply), "tokens");
    
    // Verify roles are set correctly
    const minterRole = await token.MINTER_ROLE();
    const bridgeRole = await token.BRIDGE_ROLE();
    const pauserRole = await token.PAUSER_ROLE();
    const mirrorRole = await token.MIRROR_ROLE();
    
    console.log("Roles verification:");
    console.log("- Minter role assigned:", await token.hasRole(minterRole, deployer.address));
    console.log("- Bridge role assigned:", await token.hasRole(bridgeRole, deployer.address));
    console.log("- Pauser role assigned:", await token.hasRole(pauserRole, deployer.address));
    console.log("- Mirror role assigned:", await token.hasRole(mirrorRole, deployer.address));
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
