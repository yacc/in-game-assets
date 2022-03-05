const {expect, assert} = require("chai");

const {
  initEthers,
  assertThrowsMessage,
  signPackedData,
  getTimestamp,
  getBlockNumber,
  increaseBlockTimestampBy,
} = require("./helpers");

// tests to be fixed

describe("MoblandNFT", function () {
  let MoblandNFT, nft, nftAddress, NFTFarm, farm, Coupon, coupon;

  let addr0 = "0x" + "0".repeat(40);
  let owner, validator, buyer1, buyer2, member1, member2, member3, member4, member5, member6, collector1, collector2;

  before(async function () {
    [owner, buyer1, buyer2, buyer3, validator, member1, member2, member3, member4, member5, member6, collector1, collector2] =
      await ethers.getSigners();
    MoblandNFT = await ethers.getContractFactory("MoblandNFT");
    NFTFarm = await ethers.getContractFactory("NFTFarm");
    Coupon = await ethers.getContractFactory("CouponMock");
    initEthers(ethers);
  });

  async function initAndDeploy() {
    nft = await upgrades.deployProxy(MoblandNFT, ["Mobland Character", "MLC", "https://s3.mob.land/characters/"]);
    await nft.deployed();
    // reserve 888 tokens to Mobland Genesis SYNR Pass
    // and 8000 tokens to Limited Edition coupon
    await nft.startDistribution(8889);
    coupon = await Coupon.deploy();
    await coupon.deployed();

    farm = await NFTFarm.deploy(nft.address, coupon.address, validator.address);
    await farm.deployed();
    await nft.setManager(farm.address);
  }

  async function configure() {}

  describe("constructor and initialization", async function () {
    beforeEach(async function () {
      await initAndDeploy();
    });

    it("should return the MoblandNFT address", async function () {
      await expect(await farm.validator()).to.equal(validator.address);
    });
  });

  describe("#claimTokenFromPass", async function () {
    beforeEach(async function () {
      await initAndDeploy();
    });

    it("should member1 mint a free token", async function () {
      const authCode = ethers.utils.id("a" + Math.random());
      const tokenId = 23;

      const hash = await farm.encodeForSignature(member1.address, authCode, tokenId);
      const signature = await signPackedData(hash);

      await expect(await farm.connect(member1).claimTokenFromPass(authCode, tokenId, signature))
        .to.emit(nft, "Transfer")
        .withArgs(addr0, member1.address, 23);

      assert.equal(await farm.usedCodes(authCode), member1.address);
    });

    it("should throw trying to reuse same code", async function () {
      let authCode = ethers.utils.id("a" + Math.random());
      const tokenId = 4;

      let hash = await farm.encodeForSignature(member1.address, authCode, tokenId);
      let signature = await signPackedData(hash);

      await farm.connect(member1).claimTokenFromPass(authCode, tokenId, signature);

      await assertThrowsMessage(
        farm.connect(member1).claimTokenFromPass(authCode, tokenId, signature),
        "authCode already used"
      );
    });

    it("should throw trying to set large id", async function () {
      let authCode = ethers.utils.id("a" + Math.random());
      const tokenId = 894;

      let hash = await farm.encodeForSignature(member1.address, authCode, tokenId);
      let signature = await signPackedData(hash);

      await assertThrowsMessage(farm.connect(member1).claimTokenFromPass(authCode, tokenId, signature), "id out of range");
    });
  });

  describe("#recoverLostToken", async function () {
    beforeEach(async function () {
      await initAndDeploy();
    });

    it("should give one of the lost tokens to communityMember1", async function () {
      const authCode = ethers.utils.id("a" + Math.random());
      const tokenId = 4;

      const hash = await farm.encodeForSignature(member1.address, authCode, tokenId);
      const signature = await signPackedData(hash);

      await expect(await farm.recoverLostToken(member1.address, authCode, tokenId, signature))
        .to.emit(nft, "Transfer")
        .withArgs(addr0, member1.address, 892);

      assert.equal(await farm.usedCodes(authCode), member1.address);
    });

    it("should throw if not a lost coupon", async function () {
      let authCode = ethers.utils.id("a" + Math.random());
      const tokenId = 1200;

      let hash = await farm.encodeForSignature(member1.address, authCode, tokenId);
      let signature = await signPackedData(hash);

      await assertThrowsMessage(farm.recoverLostToken(member1.address, authCode, tokenId, signature), "id not a lost coupon");
    });
  });

  describe("#swapTokenFromCoupon", async function () {
    beforeEach(async function () {
      await initAndDeploy();
      await coupon.safeMint(buyer1.address, 20);
      await coupon.safeMint(buyer1.address, 32);
      await coupon.safeMint(buyer1.address, 76);
      await coupon.safeMint(buyer1.address, 3430);
      await coupon.safeMint(buyer1.address, 7875);
    });

    it("should buyer1 have her tokens", async function () {
      await expect(await coupon.balanceOf(buyer1.address)).equal(5);
      await expect(await farm.connect(buyer1).swapTokenFromCoupon(0))
        .to.emit(nft, "Transfer")
        .withArgs(addr0, buyer1.address, 888 + 20)
        .to.emit(nft, "Transfer")
        .withArgs(addr0, buyer1.address, 888 + 32)
        .to.emit(nft, "Transfer")
        .withArgs(addr0, buyer1.address, 888 + 76)
        .to.emit(nft, "Transfer")
        .withArgs(addr0, buyer1.address, 888 + 3430)
        .to.emit(nft, "Transfer")
        .withArgs(addr0, buyer1.address, 888 + 7875);

      await expect(await coupon.balanceOf(buyer1.address)).equal(0);
      await expect(await nft.balanceOf(buyer1.address)).equal(5);
    });

    it("should buyer1 swap her tokens in two steps", async function () {
      await expect(await coupon.balanceOf(buyer1.address)).equal(5);
      await expect(await farm.connect(buyer1).swapTokenFromCoupon(3))
        .to.emit(nft, "Transfer")
        .withArgs(addr0, buyer1.address, 888 + 76)
        .to.emit(nft, "Transfer")
        .withArgs(addr0, buyer1.address, 888 + 3430)
        .to.emit(nft, "Transfer")
        .withArgs(addr0, buyer1.address, 888 + 7875);

      await expect(await coupon.balanceOf(buyer1.address)).equal(2);
      await expect(await nft.balanceOf(buyer1.address)).equal(3);

      await expect(await farm.connect(buyer1).swapTokenFromCoupon(0))
        .to.emit(nft, "Transfer")
        .withArgs(addr0, buyer1.address, 888 + 20)
        .to.emit(nft, "Transfer")
        .withArgs(addr0, buyer1.address, 888 + 32);

      await expect(await coupon.balanceOf(buyer1.address)).equal(0);
      await expect(await nft.balanceOf(buyer1.address)).equal(5);
    });

    it("should throw if trying to re-swap", async function () {
      await farm.connect(buyer1).swapTokenFromCoupon(0);
      await assertThrowsMessage(farm.connect(buyer1).swapTokenFromCoupon(0), "no tokens here");
    });
  });
});
