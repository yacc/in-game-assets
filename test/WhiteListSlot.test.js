const {expect, assert} = require("chai");

const {
  initEthers,
} = require("./helpers");

// tests to be fixed

describe("WhiteList", function () {
  let owner, holder;
  let Whitelist, wl;
  let Burner,burner

  before(async function () {
    [owner, holder] = await ethers.getSigners();
    Whitelist = await ethers.getContractFactory("WhitelistSlot");
    BurnerMock = await ethers.getContractFactory("BurnerMock");

    initEthers(ethers);
  });

  async function initAndDeploy() {
    wl = await Whitelist.deploy()
    await wl.deployed();

    burner = await BurnerMock.deploy()
    await burner.deployed();

  }

  describe.only("Whitelist Test", async function () {
    beforeEach(async function () {
      await initAndDeploy();
    });


    it("should check if set URI sets URI", async function () {
    expect(await wl.uri(0)).equal("")
    await wl.setURI("hi")
    expect(await wl.uri(0)).equal("hi")
    await wl.setURI("WHITELIST")
    expect(await wl.uri(0)).equal("WHITELIST")
    });

    it("should check set burner and get ID", async function () {
      await wl.setBurnerForID(burner.address , 55)
    expect(await wl.getIdByBurner(burner.address)).equal(55)
    await wl.setBurnerForID(burner.address , 100)
    expect(await wl.getIdByBurner(burner.address)).equal(100)
      });

    it("should batch mint", async function () {
      let ids = [1,3]
      let ammounts= [100,50]

      await wl.mintBatch(holder.address,ids,ammounts,[])
      expect(await wl.balanceOf(holder.address,ids[0])).equal(ammounts[0])
      expect(await wl.balanceOf(holder.address,ids[1])).equal(ammounts[1])
        });

    it("should batch mint", async function () {
      await wl.setBurnerForID(burner.address , 1)
      let ids = [1,3]
      let ammounts= [100,50]
      await wl.mintBatch(holder.address,ids,ammounts,[])

      let balance = await wl.balanceOf(holder.address,ids[0])
      console.log(burner)
      
      // console.log(holder)

    await wl.connect(burner).burn(holder.address,1,10)

    let balance2 = await wl.balanceOf(holder.address,ids[0])

        
  });

  });
});
