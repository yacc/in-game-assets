// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

// The staking part is taken from Everdragons2GenesisV2 contract
// https://github.com/ndujaLabs/everdragons2-core/blob/main/contracts/Everdragons2GenesisV2.sol

// Author: Francesco Sullo <francesco@superpower.io>
// (c) Superpower Labs Inc.

import "@ndujalabs/erc721playable/contracts/ERC721PlayableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@ndujalabs/wormhole721/contracts/Wormhole721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/utils/AddressUpgradeable.sol";

import "./interfaces/ISuperpowerNFTBase.sol";

//import "hardhat/console.sol";

contract SuperpowerNFTBase is
  ISuperpowerNFTBase,
  Initializable,
  ERC721Upgradeable,
  ERC721PlayableUpgradeable,
  ERC721EnumerableUpgradeable,
  Wormhole721Upgradeable
{
  using AddressUpgradeable for address;

  string private _baseTokenURI;
  bool private _baseTokenURIFrozen;

  mapping(address => bool) public pools;
  mapping(uint256 => address) public staked;

  modifier onlyPool() {
    require(pools[_msgSender()], "SuperpowerNFTBase: not a staking pool");
    _;
  }

  // solhint-disable-next-line
  function __SuperpowerNFTBase_init(
    string memory name,
    string memory symbol,
    string memory tokenUri
  ) internal initializer {
    __Wormhole721_init(name, symbol);
    __ERC721Enumerable_init();
    _baseTokenURI = tokenUri;
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721Upgradeable, ERC721PlayableUpgradeable, ERC721EnumerableUpgradeable) {
    require(!isStaked(tokenId), "SuperpowerNFTBase: staked asset");
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(Wormhole721Upgradeable, ERC721Upgradeable, ERC721PlayableUpgradeable, ERC721EnumerableUpgradeable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function updateTokenURI(string memory uri) external override onlyOwner {
    require(!_baseTokenURIFrozen, "SuperpowerNFTBase: baseTokenUri has been frozen");
    // after revealing, this allows to set up a final uri
    _baseTokenURI = uri;
  }

  function freezeTokenURI() external override onlyOwner {
    _baseTokenURIFrozen = true;
  }

  function contractURI() public view override returns (string memory) {
    return string(abi.encodePacked(_baseTokenURI, "0"));
  }

  // stakes

  function isStaked(uint256 tokenId) public view override returns (bool) {
    return staked[tokenId] != address(0);
  }

  function getStaker(uint256 tokenId) external view override returns (address) {
    return staked[tokenId];
  }

  function setPool(address pool) external override onlyOwner {
    require(pool.isContract(), "SuperpowerNFTBase: pool not a contract");
    pools[pool] = true;
  }

  function removePool(address pool) external override onlyOwner {
    require(pools[pool], "SuperpowerNFTBase: not an active pool");
    delete pools[pool];
  }

  function hasStakes(address owner) public view override returns (bool) {
    uint256 balance = balanceOf(owner);
    for (uint256 i = 0; i < balance; i++) {
      uint256 id = tokenOfOwnerByIndex(owner, i);
      if (isStaked(id)) {
        return true;
      }
    }
    return false;
  }

  function stake(uint256 tokenId) external override onlyPool {
    // pool must be approved to mark the token as staked
    require(getApproved(tokenId) == _msgSender() || isApprovedForAll(ownerOf(tokenId), _msgSender()), "Pool not approved");
    staked[tokenId] = _msgSender();
  }

  function unstake(uint256 tokenId) external override onlyPool {
    // will revert if token does not exist
    require(staked[tokenId] == _msgSender(), "SuperpowerNFTBase: wrong pool");
    delete staked[tokenId];
  }

  // emergency function in case a compromised pool is removed
  function unstakeIfRemovedPool(uint256 tokenId) external override onlyOwner {
    require(isStaked(tokenId), "SuperpowerNFTBase: not a staked tokenId");
    require(!pools[staked[tokenId]], "SuperpowerNFTBase: pool is still active");
    delete staked[tokenId];
  }

  // manage approval

  function approve(address to, uint256 tokenId) public override {
    require(!isStaked(tokenId), "SuperpowerNFTBase: staked asset");
    super.approve(to, tokenId);
  }

  function getApproved(uint256 tokenId) public view override returns (address) {
    if (isStaked(tokenId)) {
      return address(0);
    }
    return super.getApproved(tokenId);
  }

  function setApprovalForAll(address operator, bool approved) public override {
    require(!approved || !hasStakes(_msgSender()), "SuperpowerNFTBase: at least one asset is staked");
    super.setApprovalForAll(operator, approved);
  }

  function isApprovedForAll(address owner, address operator) public view override returns (bool) {
    if (hasStakes(owner)) {
      return false;
    }
    return super.isApprovedForAll(owner, operator);
  }

  // manage transfer
}
