require('dotenv').config()
const hre = require("hardhat");
const ethers = hre.ethers
const requireOrMock = require('require-or-mock')

const {
  initEthers,
  getTimestamp,
  normalize
} = require('../test/helpers')

const DeployUtils = require('./lib/DeployUtils')
let deployUtils

const deployed = requireOrMock('export/deployed.json')

async function main() {

  initEthers(ethers)
  deployUtils = new DeployUtils(ethers)
  const chainId = await deployUtils.currentChainId()
  let [deployer] = await ethers.getSigners();

  const network = chainId === 56 ? 'bsc'
      : chainId === 97 ? 'bsc_testnet'
          : 'localhost'

  if (!deployed[chainId] || !deployed[chainId].MoblandNFT) {
    console.error('MoblandNFT not deployed on', network)
    process.exit(1)
  }

  console.log(
      "Deploying contracts with the account:",
      deployer.address,
      'to', network
  );

  const MoblandNFT = await ethers.getContractFactory("MoblandNFT")
  const nft = MoblandNFT.attach(deployed[chainId].MoblandNFT)

  const GenesisFarm = await ethers.getContractFactory("GenesisFarm")

  const price = network === 'matic' ? normalize(500) : '1000000000000000'
  const delay = network === 'matic' ? 63000 : 10
  const timestamp = (await getTimestamp()) + delay
  const maxForSale = network === 'matic' ? 250 : 60
  const maxClaimable = network === 'matic' ? 350 : 90

  const genesisFarm = await GenesisFarm.deploy(
      nft.address,
      maxForSale,
      maxClaimable,
      price,
      // sale start after one hour
      timestamp
  )
  console.log("Deploying GenesisFarm");
  await genesisFarm.deployed()
  console.log("GenesisFarm deployed to:", genesisFarm.address);

  await nft.setManager(genesisFarm.address)

  console.log(`
To verify GenesisFarm source code:
    
  npx hardhat verify --show-stack-traces \\
      --network ${network} \\
      ${genesisFarm.address}  \\
      ${nft.address} \\
      ${maxForSale} \\
      ${maxClaimable} \\
      ${price} \\
      ${timestamp}
      
`)

  await deployUtils.saveDeployed(chainId, ['GenesisFarm'], [genesisFarm.address])
}

main()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
