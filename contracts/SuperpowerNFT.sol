// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

// Inspired by Everdragons2 NFTs, https://everdragons2.com
// Authors: Francesco Sullo <francesco@superpower.io>
// (c) Superpower Labs Inc.

import "./SuperpowerNFTBase.sol";
import "./interfaces/ISuperpowerNFT.sol";
import "./WhitelistSlot.sol";

//import "hardhat/console.sol";

contract SuperpowerNFT is ISuperpowerNFT, SuperpowerNFTBase {
  using AddressUpgradeable for address;
  uint256 private _nextTokenId;
  uint256 private _maxSupply;
  bool private _mintEnded;

  mapping(address => bool) public farmers;

  uint256 private _whitelistActiveUntil;
  WhitelistSlot private _wl;
  address public defaultPlayer;

  modifier onlyFarmer() {
    require(_msgSender() != address(0) && farmers[_msgSender()], "SuperpowerNFT: forbidden");
    _;
  }

  modifier canMint(uint256 amount) {
    require(canMintAmount(amount), "SuperpowerNFT: can not mint");
    _;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  function initialize(
    string memory name,
    string memory symbol,
    string memory tokenUri
  ) public initializer {
    __SuperpowerNFTBase_init(name, symbol, tokenUri);
  }

  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

  function setDefaultPlayer(address player) external onlyOwner {
    require(player.isContract(), "SuperpowerNFT: player not a contract");
    defaultPlayer = player;
  }

  function setWhitelist(address wl, uint256 activeUntil) external onlyOwner {
    if (wl != address(0)) {
      require(wl.isContract(), "SuperpowerNFT: wl not a contract");
      _wl = WhitelistSlot(wl);
    } // else we just want to update period of whitelisting
    if (activeUntil == 0) {
      activeUntil = block.timestamp;
    }
    _whitelistActiveUntil = activeUntil;
  }

  function setMaxSupply(uint256 maxSupply_) external onlyOwner {
    if (_nextTokenId == 0) {
      _nextTokenId = 1;
    }
    require(maxSupply_ > _nextTokenId - 1, "SuperpowerNFT: invalid maxSupply_");
    _maxSupply = maxSupply_;
  }

  function setFarmer(address farmer_, bool enabled) external override onlyOwner {
    require(farmer_.isContract(), "SuperpowerNFT: not a contract");
    farmers[farmer_] = enabled;
  }

  function canMintAmount(uint256 amount) public view returns (bool) {
    return _nextTokenId > 0 && !_mintEnded && _nextTokenId + amount < _maxSupply + 2;
  }

  function mint(address to, uint256 amount) external override onlyFarmer canMint(amount) {
    for (uint256 i = 0; i < amount; i++) {
      _safeMint(to, _nextTokenId++);
    }
    _burnWhitelistSlot(to, amount);
  }

  function _burnWhitelistSlot(address to, uint256 amount) internal {
    if (block.timestamp < _whitelistActiveUntil) {
      require(_wl.balanceOf(to, _wl.getIdByBurner(address(this))) >= amount, "SuperpowerNFT: not enough slot in whitelist");
      _wl.burn(to, _wl.getIdByBurner(address(this)), amount);
    }
  }

  function mintInitAndFill(
    address to,
    address player,
    uint8[31] memory initialAttributes
  ) public override onlyFarmer canMint(1) {
    _initAttributesAndSafeMint(to, _nextTokenId++, player, initialAttributes);
    _burnWhitelistSlot(to, 1);
  }

  // empty attributes
  function mintAndInit(address to, uint256 amount) external override onlyFarmer canMint(1) {
    require(defaultPlayer != address(0), "SuperpowerNFT: defaultPlayer not set");
    for (uint256 i = 0; i < amount; i++) {
      mintInitAndFill(to, defaultPlayer, _emptyAttributesArray());
    }
  }

  function endMinting() external override onlyOwner {
    _mintEnded = true;
  }

  function mintEnded() external view override returns (bool) {
    return _mintEnded;
  }

  function maxSupply() external view override returns (uint256) {
    return _maxSupply;
  }

  function nextTokenId() external view override returns (uint256) {
    return _nextTokenId;
  }
}
