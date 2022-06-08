// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

// Inspired by Everdragons2 NFTs, https://everdragons2.com
// Authors: Francesco Sullo <francesco@superpower.io>
// (c) Superpower Labs Inc.

import "./SuperpowerNFTBase.sol";
import "./interfaces/ISuperpowerNFT.sol";

//import "hardhat/console.sol";

contract SuperpowerNFT is ISuperpowerNFT, SuperpowerNFTBase {
  uint256 private _nextTokenId;
  uint256 private _maxSupply;
  bool private _mintEnded;

  mapping(address => bool) public minters;

  modifier onlyMinter() {
    require(_msgSender() != address(0) && minters[_msgSender()], "SuperpowerNFT: Forbidden");
    _;
  }

  modifier canMint(uint256 amount) {
    require(_nextTokenId > 0 && !_mintEnded && _nextTokenId + amount < _maxSupply + 2, "SuperpowerNFT: Minting ended or not started yet");
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

  function setMaxSupply(uint256 maxSupply_) external onlyOwner {
    if (_nextTokenId == 0) {
      _nextTokenId = 1;
    }
    require(maxSupply_ > _nextTokenId - 1, "SuperpowerNFT: invalid maxSupply_");
    _maxSupply = maxSupply_;
  }

  function setMinter(address minter_, bool enabled) external override onlyOwner {
    require(minter_.code.length > 0, "Not a contract");
    minters[minter_] = enabled;
  }

  function mint(address to, uint256 amount) public override onlyMinter canMint(amount) {
    require(_nextTokenId + amount - 1 < _maxSupply + 1, "Token id our of range");
    for (uint256 i = 0; i < amount; i++) {
      _safeMint(to, _nextTokenId++);
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
