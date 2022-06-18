const {expect, assert} = require("chai");

const {initEthers} = require("./helpers");

// tests to be fixed

describe("SuperpowerNFT", function () {
  let SuperpowerNFT, nft;
  let SuperpowerNFTBridged, bridgedNft;
  let FarmMock, farm;
  let Game, game;
  let owner, holder;

  before(async function () {
    [owner, holder] = await ethers.getSigners();
    SuperpowerNFT = await ethers.getContractFactory("SuperpowerNFT");
    SuperpowerNFTBridged = await ethers.getContractFactory("SuperpowerNFTBridged");
    FarmMock = await ethers.getContractFactory("FarmMock");
    Game = await ethers.getContractFactory("PlayerMockUpgradeable");

    initEthers(ethers);
  });

  async function initAndDeploy() {
    nft = await upgrades.deployProxy(SuperpowerNFT, ["Mobland Turf", "MLT", "https://s3.mob.land/turf/"]);
    await nft.deployed();

    bridgedNft = await upgrades.deployProxy(SuperpowerNFT, ["Mobland Turf", "MLT", "https://s3.mob.land/turf/"]);
    await bridgedNft.deployed();

    farm = await FarmMock.deploy(nft.address);
    await farm.deployed();

    game = await upgrades.deployProxy(Game, []);
    await game.deployed();
  }

  async function configure() {
    await nft.setMaxSupply(1000);
    await nft.setFarmer(farm.address, true);
  }

  describe("constructor and initialization", async function () {
    beforeEach(async function () {
      await initAndDeploy();
    });

    it("should revert if not authorized", async function () {
      await expect(await nft.farmers(farm.address)).equal(false);
    });
  });

  describe("#game simulation", async function () {
    // from https://github.com/ndujaLabs/erc721playable/blob/main/test/ERC721PlayableUpgradeable.test.js

    beforeEach(async function () {
      await initAndDeploy();
      await configure();
    });

    it("should mint token and verify that the player is not initiated", async function () {
      await farm.mintTokens(holder.address, 1);
      expect(await nft.ownerOf(1)).to.equal(holder.address);

      const attributes = await nft.attributesOf(holder.address, game.address);
      expect(attributes.version).to.equal(0);
    });

    it("should allow token holder to set a player", async function () {
      await farm.mintTokens(holder.address, 1);
      await nft.connect(holder).initAttributes(1, game.address);
      await game.fillInitialAttributes(
        nft.address,
        1,
        0, // keeps the existent version
        [1, 5, 34, 21, 8, 0, 34, 12, 31, 65, 178, 243, 2]
      );

      const attributes = await nft.attributesOf(1, game.address);
      expect(attributes.version).to.equal(1);
      expect(attributes.attributes[2]).to.equal(34);
    });

    it("should update the levels in PlayerMock", async function () {
      await farm.mintTokens(holder.address, 1);
      await nft.connect(holder).initAttributes(1, game.address);
      await game.fillInitialAttributes(
        nft.address,
        1,
        0, // keeps the existent version
        [1, 5, 34, 21, 8, 0, 34, 12, 31, 65, 178, 243, 2]
      );

      let attributes = await nft.attributesOf(1, game.address);
      let levelIndex = 3;
      expect(attributes.attributes[levelIndex]).to.equal(21);

      await game.levelUp(nft.address, 1, levelIndex, 63);

      attributes = await nft.attributesOf(1, game.address);
      expect(attributes.attributes[levelIndex]).to.equal(63);
    });

    it("should check if nft is playable", async function () {
      assert.isTrue(await game.isNFTPlayable(nft.address));
      expect(game.isNFTPlayable(farm.address)).reverted;
    });
  });
});
