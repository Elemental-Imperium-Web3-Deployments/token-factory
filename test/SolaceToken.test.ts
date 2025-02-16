import { expect } from "chai";
import { ethers } from "hardhat";
import { SolaceToken } from "../typechain-types";
import { SignerWithAddress } from "@nomicfoundation/hardhat-ethers/signers";

describe("SolaceToken", function () {
  let token: SolaceToken;
  let owner: SignerWithAddress;
  let addr1: SignerWithAddress;
  let addr2: SignerWithAddress;

  beforeEach(async function () {
    [owner, addr1, addr2] = await ethers.getSigners();
    const Token = await ethers.getContractFactory("SolaceToken");
    token = await Token.deploy();
  });

  describe("Deployment", function () {
    it("Should assign all roles to the owner", async function () {
      const minterRole = await token.MINTER_ROLE();
      const bridgeRole = await token.BRIDGE_ROLE();
      const pauserRole = await token.PAUSER_ROLE();
      
      expect(await token.hasRole(minterRole, owner.address)).to.equal(true);
      expect(await token.hasRole(bridgeRole, owner.address)).to.equal(true);
      expect(await token.hasRole(pauserRole, owner.address)).to.equal(true);
    });
  });

  describe("Minting", function () {
    it("Should allow minting by minter role", async function () {
      await token.mint(addr1.address, 100);
      expect(await token.balanceOf(addr1.address)).to.equal(100);
    });
  });
});
