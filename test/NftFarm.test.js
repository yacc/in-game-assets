const {expect, assert} = require("chai");

const {initEthers} = require("./helpers");
const {getCurrentTimestamp} = require("hardhat/internal/hardhat-network/provider/utils/getCurrentTimestamp");

// tests to be fixed

describe("NftFarm", function () {
  let owner, whitelisted, notWhitelisted;
  let Whitelist, wl;
  let SuperpowerNFT, nft;
  let NftFarm, farm;
  let Game, game;

  before(async function () {
    [owner, whitelisted, notWhitelisted] = await ethers.getSigners();
    Whitelist = await ethers.getContractFactory("WhitelistSlot");
    SuperpowerNFT = await ethers.getContractFactory("SuperpowerNFT");
    NftFarm = await ethers.getContractFactory("NftFarm");
    Game = await ethers.getContractFactory("PlayerMockUpgradeable");
    initEthers(ethers);
  });

  async function initAndDeploy() {
    wl = await Whitelist.deploy();
    await wl.deployed();

    nft = await upgrades.deployProxy(SuperpowerNFT, ["Mobland Turf", "MLT", "https://s3.mob.land/turf/"]);
    await nft.deployed();

    farm = await upgrades.deployProxy(NftFarm, []);
    await farm.deployed();

    const id = 1;
    const amount = 5;
    await wl.mintBatch(whitelisted.address, [id], [amount], []);
    await wl.setBurnerForID(nft.address, id);
    await nft.setWhitelist(wl.address, (await getCurrentTimestamp()) + 1e4);
    await nft.setFarmer(farm.address, true);
    await farm.setNewNft(nft.address);
    await farm.setPrice(1, ethers.utils.parseEther("1"));
    game = await upgrades.deployProxy(Game, []);
    await game.deployed();
  }

  describe("Buy tokens", async function () {
    beforeEach(async function () {
      await initAndDeploy();
    });

    it("should not buy because no payment", async function () {
      expect(farm.connect(whitelisted).buyTokens(1, 3)).revertedWith("NftFarm: insufficient payment");
    });

    it("should revert maxSupply not set or defaultPlayer not set", async function () {
      expect(await nft.canMintAmount(3)).equal(false);

      await expect(
        farm.connect(whitelisted).buyTokens(1, 3, {
          value: ethers.BigNumber.from(await farm.getPrice(1)).mul(3),
        })
      ).revertedWith("SuperpowerNFT: can not mint");

      await nft.setMaxSupply(1000);

      expect(await nft.canMintAmount(3)).equal(true);

      await expect(
        farm.connect(whitelisted).buyTokens(1, 3, {
          value: ethers.BigNumber.from(await farm.getPrice(1)).mul(3),
        })
      ).revertedWith("SuperpowerNFT: defaultPlayer not set");
    });

    it("should buy tokens", async function () {
      await nft.setMaxSupply(1000);
      await nft.setDefaultPlayer(game.address);

      expect(await nft.defaultPlayer()).equal(game.address);
      expect(await wl.balanceOf(whitelisted.address, 1)).equal(5);

      expect(
        await farm.connect(whitelisted).buyTokens(1, 3, {
          value: ethers.BigNumber.from(await farm.getPrice(1)).mul(3),
        })
      )
        .to.emit(nft, "Transfer")
        .withArgs(ethers.constants.AddressZero, whitelisted.address, 1)
        .to.emit(nft, "Transfer")
        .withArgs(ethers.constants.AddressZero, whitelisted.address, 2)
        .to.emit(nft, "Transfer")
        .withArgs(ethers.constants.AddressZero, whitelisted.address, 3);

      expect(await nft.nextTokenId()).equal(4);
      expect(await wl.balanceOf(whitelisted.address, 1)).equal(2);
    });

    it("should can not buy tokens because not whitelisted", async function () {
      await nft.setMaxSupply(1000);
      await nft.setDefaultPlayer(game.address);

      expect(await wl.balanceOf(notWhitelisted.address, 1)).equal(0);

      await expect(
        farm.connect(notWhitelisted).buyTokens(1, 3, {
          value: ethers.BigNumber.from(await farm.getPrice(1)).mul(3),
        })
      ).revertedWith("SuperpowerNFT: not enough slot in whitelist");
    });

    it("should buy tokens when whitelist period ends", async function () {
      await nft.setMaxSupply(1000);
      await nft.setDefaultPlayer(game.address);

      expect(await nft.defaultPlayer()).equal(game.address);

      await nft.setWhitelist(ethers.constants.AddressZero, 0);

      expect(
        await farm.connect(notWhitelisted).buyTokens(1, 3, {
          value: ethers.BigNumber.from(await farm.getPrice(1)).mul(3),
        })
      )
        .to.emit(nft, "Transfer")
        .withArgs(ethers.constants.AddressZero, notWhitelisted.address, 1)
        .to.emit(nft, "Transfer")
        .withArgs(ethers.constants.AddressZero, notWhitelisted.address, 2)
        .to.emit(nft, "Transfer")
        .withArgs(ethers.constants.AddressZero, notWhitelisted.address, 3);

      expect(await nft.nextTokenId()).equal(4);
    });
  });
});
