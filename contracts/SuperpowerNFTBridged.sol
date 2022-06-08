// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

// Authors: Francesco Sullo <francesco@superpower.io>
// (c) Superpower Labs Inc.

import "./SuperpowerNFTBase.sol";

//import "hardhat/console.sol";

contract SuperpowerNFTBridged is SuperpowerNFTBase {
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
}
