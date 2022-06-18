const {expect, assert} = require("chai");

const {initEthers} = require("./helpers");

// tests to be fixed

describe("WhiteList", function () {
  let owner, holder;
  let Whitelist, wl;
  let Burner, burner;

  before(async function () {
    [owner, holder] = await ethers.getSigners();
    Whitelist = await ethers.getContractFactory("WhitelistSlot");
    BurnerMock = await ethers.getContractFactory("BurnerMock");

    initEthers(ethers);
  });

  async function initAndDeploy() {
    wl = await Whitelist.deploy();
    await wl.deployed();

    burner = await BurnerMock.deploy(wl.address);
    await burner.deployed();
  }

  describe("Whitelist Test", async function () {
    beforeEach(async function () {
      await initAndDeploy();
    });

    it("should check if set URI sets URI", async function () {
      expect(await wl.uri(0)).equal("");
      await wl.setURI("https://s3.mob.land/Whitelist");
      expect(await wl.uri(0)).equal("https://s3.mob.land/Whitelist");
      await wl.setURI("https://s3.mob.land/WHITE");
      expect(await wl.uri(0)).equal("https://s3.mob.land/WHITE");
    });

    it("should check set burner and get ID", async function () {
      await wl.setBurnerForID(burner.address, 55);
      expect(await wl.getIdByBurner(burner.address)).equal(55);
      await wl.setBurnerForID(burner.address, 100);
      expect(await wl.getIdByBurner(burner.address)).equal(100);
      expect(wl.setBurnerForID(holder.address, 100)).revertedWith("WhitelistSlot: burner not a contract");
    });

    it("should batch mint", async function () {
      let ids = [1, 3];
      let ammounts = [100, 50];

      await wl.mintBatch(holder.address, ids, ammounts, []);
      expect(await wl.balanceOf(holder.address, ids[0])).equal(ammounts[0]);
      expect(await wl.balanceOf(holder.address, ids[1])).equal(ammounts[1]);
    });

    it("should mint and burn", async function () {
      const ids = [1, 3];
      const ammounts = [100, 50];
      const burnAmmount = 10;
      await wl.mintBatch(holder.address, ids, ammounts, []);
      await wl.setBurnerForID(burner.address, ids[0]);

      let balance = await wl.balanceOf(holder.address, ids[0]);
      await burner.burn(holder.address, ids[0], burnAmmount);
      let balance2 = await wl.balanceOf(holder.address, ids[0]);
      expect(balance2).equal(balance.sub(burnAmmount));
      balance = await wl.balanceOf(holder.address, ids[1]);
      expect(burner.burn(holder.address, ids[1], burnAmmount)).revertedWith("Not the final NFT");
      await wl.setBurnerForID(burner.address, ids[1]);
      await burner.burn(holder.address, ids[1], burnAmmount);
      balance2 = await wl.balanceOf(holder.address, ids[1]);
      expect(balance2).equal(balance.sub(burnAmmount));
    });
  });
});
