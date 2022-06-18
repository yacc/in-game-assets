// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

// Author : Francesco Sullo < francesco@superpower.io>
// (c) Superpower Labs Inc.

import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/math/SafeMathUpgradeable.sol";
import "soliutils/contracts/UUPSUpgradableTemplate.sol";

import "./interfaces/ISuperpowerNFT.sol";

import "hardhat/console.sol";

contract NftFarm is UUPSUpgradableTemplate {
  using AddressUpgradeable for address;
  using SafeMathUpgradeable for uint256;

  event NewPriceFor(uint8 nftId, uint256 price);
  event FarmerSetFor(uint8 nftId, address farmer);
  event FarmerRemovedFor(uint8 nftId, address farmer);
  event NewNftForSale(uint8 nftId, address nft);
  event NftRemovedFromSale(uint8 nftId, address nft);

  mapping(uint8 => ISuperpowerNFT) private _nfts;
  mapping(address => uint8) private _nftsByAddress;
  uint8 private _lastNft;
  mapping(uint8 => address) private _farmers;
  mapping(uint8 => uint256) private _prices;

  uint256 public proceedsBalance;

  modifier onlyFarmer(uint8 nftId) {
    require(nftIdByFarmer(_msgSender()) == nftId, "NftFarm: not a farmer for this nft");
    _;
  }

  function initialize() public initializer {
    __UUPSUpgradableTemplate_init();
  }

  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

  function setNewNft(address nft) external onlyOwner {
    require(nft.isContract(), "NftFarm: not a contract");
    require(_nftsByAddress[nft] == 0, "NftFarm: token already set");
    _lastNft++;
    _nftsByAddress[nft] = _lastNft;
    _nfts[_lastNft] = ISuperpowerNFT(nft);
    emit NewNftForSale(_lastNft, nft);
  }

  function removeNewNft(address nft) external onlyOwner {
    require(_nftsByAddress[nft] > 0, "NftFarm: token not found");
    uint8 nftId = _nftsByAddress[nft];
    delete _nfts[nftId];
    delete _nftsByAddress[nft];
    emit NftRemovedFromSale(nftId, nft);
  }

  function setFarmer(uint8 nftId, address farmer) external onlyOwner {
    require(farmer.isContract(), "NftFarm: not a contract");
    _farmers[nftId] == farmer;
    emit FarmerSetFor(nftId, farmer);
  }

  function removeFarmerForNft(uint8 nftId, address farmer) external onlyOwner {
    require(_farmers[nftId] == farmer, "NftFarm: farmer not found");
    delete _farmers[nftId];
    emit FarmerRemovedFor(nftId, farmer);
  }

  function setPrice(uint8 nftId, uint256 price) external onlyOwner {
    require(address(_nfts[nftId]) != address(0), "NftFarm: token not found");
    _prices[nftId] = price;
    emit NewPriceFor(nftId, price);
  }

  function getPrice(uint8 nftId) external view returns (uint) {
    return _prices[nftId];
  }

  function nftIdByFarmer(address farmer) public view returns (uint8) {
    for (uint8 i = 0; i < _lastNft + 1; i++) {
      if (_farmers[i] == farmer) {
        return i;
      }
    }
    return 0;
  }

  function buyTokens(uint8 nftId, uint256 amount) external payable {
    require(msg.value >= _prices[nftId].mul(amount), "NftFarm: insufficient payment");
    proceedsBalance += msg.value;
    _nfts[nftId].mintAndInit(_msgSender(), amount);
  }

  function withdrawProceeds(address beneficiary, uint256 amount) public onlyOwner {
    if (amount == 0) {
      amount = proceedsBalance;
    }
    require(amount <= proceedsBalance, "NftFarm: insufficient funds");
    proceedsBalance -= amount;
    (bool success, ) = beneficiary.call{value: amount}("");
    require(success);
  }
}
