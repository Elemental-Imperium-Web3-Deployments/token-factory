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
      const bridgeRole = await token.BRIDGE_ROLE();
      const pauserRole = await token.PAUSER_ROLE();
      const mirrorRole = await token.MIRROR_ROLE();
      
      expect(await token.hasRole(minterRole, owner.address)).to.equal(true);
      expect(await token.hasRole(bridgeRole, owner.address)).to.equal(true);
      expect(await token.hasRole(pauserRole, owner.address)).to.equal(true);
      expect(await token.hasRole(mirrorRole, owner.address)).to.equal(true);
    });
  });

  describe("Core Functions", function () {
    beforeEach(async function () {
      await token.mint(owner.address, ethers.utils.parseEther("1000"));
    });

    it("Should allow minting by minter role", async function () {
      await token.mint(addr1.address, 100);
      expect(await token.balanceOf(addr1.address)).to.equal(100);
    });

    it("Should allow burning tokens", async function () {
      await token.transfer(addr1.address, 100);
      await token.connect(addr1).burn(50);
      expect(await token.balanceOf(addr1.address)).to.equal(50);
    });

    it("Should execute swaps correctly", async function () {
      await token.transfer(addr1.address, 100);
      await token.connect(addr1).swap(addr2.address, 50);
      expect(await token.balanceOf(addr2.address)).to.equal(50);
    });

    it("Should revert swap with zero amount", async function () {
      await expect(token.swap(addr1.address, 0)).to.be.revertedWith("InvalidSwapAmount");
    });
  });

  describe("Mirroring", function () {
    beforeEach(async function () {
      await token.mint(addr1.address, 1000);
    });

    it("Should create and redeem mirrors", async function () {
      await token.connect(addr1).createMirror(500);
      expect(await token.mirroredBalances(addr1.address)).to.equal(500);
      expect(await token.balanceOf(addr1.address)).to.equal(500);

      await token.connect(addr1).redeemMirror(200);
      expect(await token.mirroredBalances(addr1.address)).to.equal(300);
      expect(await token.balanceOf(addr1.address)).to.equal(700);
    });

    it("Should revert mirror operations with invalid amounts", async function () {
      await expect(token.connect(addr1).createMirror(0))
        .to.be.revertedWith("InvalidMirrorAmount");
      
      await expect(token.connect(addr1).redeemMirror(100))
        .to.be.revertedWith("InvalidMirrorAmount");
    });
  });

  describe("Bridging", function () {
    const targetChainId = 43114; // Avalanche C-Chain
    const mockProof = ethers.utils.randomBytes(32);

    beforeEach(async function () {
      await token.mint(addr1.address, 1000);
    });

    it("Should bridge tokens", async function () {
      await expect(token.connect(addr1).bridgeTokens(500, targetChainId))
        .to.emit(token, "TokensBridged")
        .withArgs(addr1.address, 500, targetChainId);
      
      expect(await token.balanceOf(addr1.address)).to.equal(500);
    });

    it("Should receive bridged tokens", async function () {
      await expect(token.connect(owner).receiveBridgedTokens(addr2.address, 500, targetChainId, mockProof))
        .to.emit(token, "TokensReceived")
        .withArgs(addr2.address, 500, targetChainId);
      
      expect(await token.balanceOf(addr2.address)).to.equal(500);
    });

    it("Should prevent duplicate bridge transactions", async function () {
      await token.connect(owner).receiveBridgedTokens(addr2.address, 500, targetChainId, mockProof);
      
      await expect(token.connect(owner).receiveBridgedTokens(addr2.address, 500, targetChainId, mockProof))
        .to.be.revertedWith("BridgeError");
    });
  });

  describe("Flash Loans", function () {
    const loanAmount = ethers.utils.parseEther("100");
    
    beforeEach(async function () {
      await token.mint(mockBridgeReceiver.address, ethers.utils.parseEther("1000"));
    });

    it("Should execute flash loan and collect fees", async function () {
      const fee = loanAmount.mul(9).div(10000); // 0.09% fee
      await mockBridgeReceiver.setShouldRepay(true);
      
      await expect(token.flashLoan(mockBridgeReceiver.address, loanAmount, "0x"))
        .to.emit(token, "FlashLoan")
        .withArgs(mockBridgeReceiver.address, loanAmount);
    });

    it("Should revert if flash loan is not repaid", async function () {
      await mockBridgeReceiver.setShouldRepay(false);
      
      await expect(token.flashLoan(mockBridgeReceiver.address, loanAmount, "0x"))
        .to.be.revertedWith("FlashLoanNotRepaid");
    });
  });
});
