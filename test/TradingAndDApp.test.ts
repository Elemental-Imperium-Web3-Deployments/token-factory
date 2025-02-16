import { expect } from "chai";
import { ethers } from "hardhat";
import { Contract } from "ethers";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import "@nomiclabs/hardhat-waffle";

describe("SolaceToken Trading and DApp Integration", function () {
  let token: Contract;
  let owner: SignerWithAddress;
  let bot: SignerWithAddress;
  let dapp: SignerWithAddress;
  let user: SignerWithAddress;

  beforeEach(async function () {
    [owner, bot, dapp, user] = await ethers.getSigners();
    const Token = await ethers.getContractFactory("SolaceToken");
    token = await Token.deploy();
    await token.deployed();
  });

  describe("Trading Bot Integration", function () {
    it("Should register and deregister trading bots", async function () {
      await token.registerBot(bot.address, "arbitrage_bot");
      expect(await token.isBotRegistered(bot.address)).to.equal(true);
      expect(await token.getBotType(bot.address)).to.equal("arbitrage_bot");

      await token.deregisterBot(bot.address);
      expect(await token.isBotRegistered(bot.address)).to.equal(false);
    });

    it("Should execute trades from registered bots", async function () {
      await token.registerBot(bot.address, "arbitrage_bot");
      await token.mint(bot.address, ethers.utils.parseEther("1000"));

      await expect(token.connect(bot).executeTrade(
        token.address,
        ethers.constants.AddressZero,
        ethers.utils.parseEther("100"),
        ethers.utils.parseEther("95"),
        "0x"
      )).to.emit(token, "TradeExecuted");
    });
  });

  describe("DApp Integration", function () {
    it("Should register and deregister DApps", async function () {
      await token.connect(dapp).registerDApp("lending_protocol", "metadata_uri");
      expect(await token.isDAppRegistered(dapp.address)).to.equal(true);

      const metadata = await token.getDAppMetadata(dapp.address);
      expect(metadata.dappType).to.equal("lending_protocol");
      expect(metadata.metadata).to.equal("metadata_uri");

      await token.connect(dapp).deregisterDApp();
      expect(await token.isDAppRegistered(dapp.address)).to.equal(false);
    });

    it("Should allow DApp interactions", async function () {
      await token.connect(dapp).registerDApp("lending_protocol", "metadata_uri");
      
      await expect(token.connect(user).interactWithDApp(
        dapp.address,
        ethers.utils.defaultAbiCoder.encode(["string"], ["test_interaction"])
      )).to.emit(token, "DAppInteraction");
    });

    it("Should revert interactions with unregistered DApps", async function () {
      await expect(token.connect(user).interactWithDApp(
        dapp.address,
        ethers.utils.defaultAbiCoder.encode(["string"], ["test_interaction"])
      )).to.be.revertedWith("DApp not registered");
    });
  });
});
