// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "../WhitelistSlot.sol";
import "hardhat/console.sol";

contract BurnerMock{

WhitelistSlot public whitelist;

/// @custom:oz-upgrades-unsafe-allow constructor
  constructor(address whitelist_) {
  require(whitelist_.code.length > 0, "Not a contract");  
  whitelist = WhitelistSlot(whitelist_);
  }

//   function mintTokens(address to, uint256[] ids, uint256[] amounts, bytes memory data) public {
//   whitelist.mintBatch(to,ids, amounts, data);
//   }
  function burn(address account, uint256 id, uint256 amount) public {
  whitelist.burn(account,id, amount);
  }
  
}