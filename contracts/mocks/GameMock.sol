// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Author: Francesco Sullo <francesco@sullo.co>
// 'ndujaLabs, https://ndujalabs.com

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

import "@ndujalabs/erc721playable/contracts/ERC721PlayableUpgradeable.sol";

import "hardhat/console.sol";

contract GameMock is Initializable, OwnableUpgradeable, UUPSUpgradeable {
  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  function initialize() public initializer {
    __Ownable_init();
    __UUPSUpgradeable_init();
  }

  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

  function isTokenInitialized(ERC721PlayableUpgradeable _nft, uint256 _tokenId) public view returns (bool) {
    require(isNFTPlayable(address(_nft)), "not a playable NFT");
    return _nft.attributesOf(_tokenId, address(this)).version > 0;
  }

  function updateAttributes(
    address _nft,
    uint256 _tokenId,
    uint256[] memory indexes,
    uint8[] memory attributes
  ) external onlyOwner {
    ERC721PlayableUpgradeable nft = ERC721PlayableUpgradeable(_nft);
    nft.updateAttributes(_tokenId, 0, indexes, attributes);
  }

  function isNFTPlayable(address _nft) public view returns (bool) {
    ERC721PlayableUpgradeable nft = ERC721PlayableUpgradeable(_nft);
    return nft.supportsInterface(0xac517b2e);
  }
}
