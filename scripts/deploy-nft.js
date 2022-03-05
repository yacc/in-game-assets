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

  console.log("Account balance:", (await deployer.getBalance()).toString());

  MoblandNFT = await ethers.getContractFactory("MoblandNFT")
  nft = await upgrades.deployProxy(MoblandNFT, [
    "Mobland Character",
    "MLC",
    "https://s3.mob.land/characters/"
  ])

  await nft.deployed()
  console.log("MoblandNFT deployed to:", nft.address);

  console.log(`
To verify MoblandNFT source code:

  npx hardhat verify --show-stack-traces \\
      --network ${network} \\
      ${nft.address} \\
      "Mobland Character" \\
      "MLC" \\
      "https://s3.mob.land/characters/"

`)

  await deployUtils.saveDeployed(chainId, ['MoblandNFT'], [nft.address])

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });

