import { expect } from "chai";
import { ethers } from "hardhat";
import { Contract } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

describe("SolaceToken", function () {
  let token: Contract;
  let owner: SignerWithAddress;
  let addr1: SignerWithAddress;
  let addr2: SignerWithAddress;
  let mockBridgeReceiver: Contract;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();
    const Token = await ethers.getContractFactory("SolaceToken");
    token = await Token.deploy();
    await token.deployed();

    // Deploy mock flash loan receiver for testing
    const MockReceiver = await ethers.getContractFactory("MockFlashLoanReceiver");
    mockBridgeReceiver = await MockReceiver.deploy(token.address);
    await mockBridgeReceiver.deployed();
  });

  describe("Deployment", function () {
    it("Should assign all roles to the owner", async function () {
      const minterRole = await token.MINTER_ROLE();
      const pauserRole = await token.PAUSER_ROLE();
      
      expect(await token.hasRole(minterRole, owner.address)).to.equal(true);
      expect(await token.hasRole(pauserRole, owner.address)).to.equal(true);
    });
  });

  describe("Core Functions", function () {
    it("Should allow minting by minter role", async function () {
      const mintAmount = ethers.utils.parseEther("48617055"); // 500 BTC worth @ ~97,234.11 USD/BTC
      await token.mint(addr1.address, mintAmount);
      expect(await token.balanceOf(addr1.address)).to.equal(mintAmount);
    });

    it("Should revert when non-minter tries to mint", async function () {
      const mintAmount = ethers.utils.parseEther("1000");
      await expect(token.connect(addr1).mint(addr2.address, mintAmount))
        .to.be.revertedWith("AccessControl: account " + addr1.address.toLowerCase() + " is missing role " + await token.MINTER_ROLE());
    });
  });
});
