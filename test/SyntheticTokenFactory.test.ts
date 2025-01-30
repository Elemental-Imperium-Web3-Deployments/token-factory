import { expect } from "chai";
import { ethers, upgrades } from "hardhat";
import { Contract } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { SyntheticTokenFactory, SyntheticTokenImplementation } from "../typechain-types";

describe("SyntheticTokenFactory", function() {
    let factory: SyntheticTokenFactory;
    let implementation: SyntheticTokenImplementation;
    let owner: SignerWithAddress;
    let mockOracle: SignerWithAddress;

    beforeEach(async function() {
        [owner, mockOracle] = await ethers.getSigners();
        
        // Deploy implementation contract first
        const ImplementationFactory = await ethers.getContractFactory("SyntheticTokenImplementation");
        implementation = await ImplementationFactory.deploy() as SyntheticTokenImplementation;
        await implementation.deployed();
        
        // Deploy factory with UUPS proxy
        const Factory = await ethers.getContractFactory("SyntheticTokenFactory");
        const proxy = await upgrades.deployProxy(Factory, [], {
            kind: "uups",
            initializer: "initialize",
            unsafeAllow: ["constructor"]
        });
        await proxy.deployed();
        
        factory = Factory.attach(proxy.address) as SyntheticTokenFactory;
        
        // Verify deployment
        expect(await factory.deployed()).to.equal(factory);
    });

    it("Should deploy a synthetic fiat token", async function() {
        const tx = await factory.deployToken(
            "Synthetic USD",
            "sUSD",
            0, // FIAT category
            "USD",
            mockOracle.address
        );
        
        const receipt = await tx.wait();
        expect(receipt.status).to.equal(1);
        
        const tokenAddress = await factory.tokensBySymbol("sUSD");
        expect(tokenAddress).to.not.equal(ethers.constants.AddressZero);
    });

    it("Should deploy tokens of different categories", async function() {
        const categories = [
            { name: "Synthetic USD", symbol: "sUSD", category: 0, asset: "USD" },
            { name: "Synthetic Gold", symbol: "sGLD", category: 1, asset: "XAU" },
            { name: "Synthetic Tesla", symbol: "sTSLA", category: 2, asset: "TSLA" }
        ];
        
        for (const token of categories) {
            const tx = await factory.deployToken(
                token.name,
                token.symbol,
                token.category,
                token.asset,
                mockOracle.address
            );
            
            const receipt = await tx.wait();
            expect(receipt.status).to.equal(1);
            
            const tokenAddress = await factory.tokensBySymbol(token.symbol);
            expect(tokenAddress).to.not.equal(ethers.constants.AddressZero);
            
            const categoryTokens = await factory.tokensByCategory(token.category, 0);
            expect(categoryTokens).to.equal(tokenAddress);
        }
    });

    it("Should not allow deploying tokens with duplicate symbols", async function() {
        await factory.deployToken(
            "Synthetic USD",
            "sUSD",
            0,
            "USD",
            mockOracle.address
        );

        await expect(
            factory.deployToken(
                "Synthetic USD 2",
                "sUSD",
                0,
                "USD",
                mockOracle.address
            )
        ).to.be.revertedWith("Token already exists");
    });
});
