import { ethers, upgrades } from "hardhat";

async function main() {
    // Deploy Price Feed Aggregator
    const PriceFeedAggregator = await ethers.getContractFactory("PriceFeedAggregator");
    const priceFeedAggregator = await PriceFeedAggregator.deploy();
    await priceFeedAggregator.waitForDeployment();
    console.log("PriceFeedAggregator deployed to:", await priceFeedAggregator.getAddress());

    // Deploy Token Factory
    const Factory = await ethers.getContractFactory("SyntheticTokenFactory");
    const factory = await upgrades.deployProxy(Factory);
    await factory.waitForDeployment();
    console.log("SyntheticTokenFactory deployed to:", await factory.getAddress());

    // Deploy Governance
    const Governance = await ethers.getContractFactory("TokenFactoryGovernance");
    const governance = await Governance.deploy(await factory.getAddress());
    await governance.waitForDeployment();
    console.log("TokenFactoryGovernance deployed to:", await governance.getAddress());
}

main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
