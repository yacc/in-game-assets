require('dotenv').config()
const hre = require("hardhat");
const ethers = hre.ethers

const DeployUtils = require('./lib/DeployUtils')
let deployUtils

async function main() {
  deployUtils = new DeployUtils(ethers)

  const chainId = await deployUtils.currentChainId()
  let [deployer] = await ethers.getSigners();

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
  console.debug("Tx:", nft.deployTransaction.hash);
  await nft.deployed()
  console.log("SuperpowerNFT deployed to:", nft.address);

  console.log("To verify SuperpowerNFT flatten the code and sumbit it for the implementation")

  let prefix = /turf/i.test(NAME) ? "TurfToken" : /farm/i.test(NAME) ? "FarmToken" : SYMBOL;
  await deployUtils.saveDeployed(chainId, [`${prefix}|SuperpowerNFT`], [nft.address])
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

