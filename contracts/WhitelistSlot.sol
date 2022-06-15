// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Address.sol";

import "./SuperpowerNFT.sol";

contract WhitelistSlot is ERC1155, Ownable {
  using Address for address;

  constructor() ERC1155("") {}

  mapping(address => uint256) private _burners;

  modifier onlyBurner(uint256 id) {
    require(_burners[_msgSender()] == id, "Not the final NFT");
    _;
  }

  function setURI(string memory newUri) public onlyOwner {
    _setURI(newUri);
  }

  function setBurnerForID(address burner, uint256 id) external onlyOwner {
    require(burner.isContract(), "WhitelistSlot: burner not a contract");
    _burners[burner] = id;
  }

  function getIdByBurner(address burner) public view returns(uint) {
    return _burners[burner];
  }

  // airdropped to wallets to be whitelisted
  function mintBatch(
    address to,
    uint256[] memory ids,
    uint256[] memory amounts,
    bytes memory data
  ) public onlyOwner {
    _mintBatch(to, ids, amounts, data);
  }

  function burn(
    address account,
    uint256 id,
    uint256 amount
  ) public virtual onlyBurner(id) {
    _burn(account, id, amount);
  }
}
