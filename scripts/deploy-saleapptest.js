require('dotenv').config()
const hre = require("hardhat");
const ethers = hre.ethers
const {getCurrentTimestamp} = require("hardhat/internal/hardhat-network/provider/utils/getCurrentTimestamp");


const DeployUtils = require('./lib/DeployUtils')
let deployUtils


async function main() {
  deployUtils = new DeployUtils(ethers)

  const chainId = await deployUtils.currentChainId()
  let [deployer, whitelisted] = await ethers.getSigners();


  const network = chainId === 56 ? 'bsc'
      : chainId === 97 ? 'bsc_testnet'
          : 'localhost'

  console.log(
      "Deploying contracts with the account:",
      deployer.address,
      'to', network
  );

  const { NAME, SYMBOL, TOKEN_URI } = process.env
  if (!NAME || !SYMBOL || !TOKEN_URI) {
    console.error("Missing parameters")
    process.exit(1);
  }

  console.log("Account balance:", (await deployer.getBalance()).toString());

  const SuperpowerNFT = await ethers.getContractFactory("SuperpowerNFT")
  const nft = await upgrades.deployProxy(SuperpowerNFT, [
    NAME,
    SYMBOL,
    TOKEN_URI
  ])

  const Whitelist = await ethers.getContractFactory("WhitelistSlot");
  const wl = await Whitelist.deploy();

  const FARM = await ethers.getContractFactory("NftFarm")
  const farm = await upgrades.deployProxy(FARM, [])
  
  const Game = await ethers.getContractFactory("PlayerMockUpgradeable");
  const game = await upgrades.deployProxy(Game, []);


  await wl.deployed()
  await nft.deployed()
  await farm.deployed()
  await game.deployed()

  const id = 1;
  const amount = 5;
  await wl.mintBatch(whitelisted.address, [id], [amount], []);
  await wl.setBurnerForID(nft.address, id);
  await nft.setWhitelist(wl.address, (await getCurrentTimestamp()) + 1e6);
  await nft.setFarmer(farm.address, true);
  await farm.setNewNft(nft.address);
  await farm.setPrice(1, ethers.utils.parseEther("1"));
  await nft.setMaxSupply(1000);
  await nft.setDefaultPlayer(game.address);


  await farm.connect(whitelisted).buyTokens(1, 2, {
    value: ethers.BigNumber.from((await farm.getPrice(1)).mul(2)),
  })


  console.log("SuperpowerNFT deployed to:", nft.address);
  console.log("Sale Farm deployed to:", farm.address);
  console.log("Player Mock deployed to:", game.address);
  console.log("initialized white listed at ", whitelisted.address)



  let prefix = /turf/i.test(NAME) ? "TurfToken" : /farm/i.test(NAME) ? "FarmToken" : SYMBOL;
  await deployUtils.saveDeployed(chainId, [`${prefix}|SuperpowerNFT`], [nft.address])
  await deployUtils.saveDeployed(chainId, [`NftFarm`], [farm.address])
  await deployUtils.saveDeployed(chainId, [`WhitelistSlot`], [wl.address])


}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

