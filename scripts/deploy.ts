import { ethers } from "hardhat";

async function main() {
    const [deployer] = await ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    const SolaceToken = await ethers.getContractFactory("SolaceToken");
    const token = await SolaceToken.deploy();
    await token.deployed();

    console.log("SolaceToken deployed to:", token.address);

    // Mint initial supply (500 BTC worth @ ~97,234.11 USD/BTC = ~48.6M USD)
    const initialSupply = ethers.utils.parseEther("48617055");
    await token.mint(deployer.address, initialSupply);
    
    console.log("Initial supply minted:", ethers.utils.formatEther(initialSupply), "tokens");
    
    // Verify roles are set correctly
    const minterRole = await token.MINTER_ROLE();
    const pauserRole = await token.PAUSER_ROLE();
    
    console.log("Roles verification:");
    console.log("- Minter role assigned:", await token.hasRole(minterRole, deployer.address));
    console.log("- Pauser role assigned:", await token.hasRole(pauserRole, deployer.address));
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });
