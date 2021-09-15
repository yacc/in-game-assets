// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Author: Francesco Sullo <francesco@sullo.co>
// EverDragons2, https://everdragons2.com

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "./IEverDragons2.sol";
import "./DragonsMaster.sol";

contract EverDragons2 is IEverDragons2, ERC721, ERC721Enumerable, Ownable {
  address public manager;

  string private _uri = "https://everdragons2.com/metadata/";

  modifier onlyManager() {
    require(_msgSender() == manager, "Forbidden");
    _;
  }

  constructor() ERC721("EverDragons2", "ED2") {
    _mint(msg.sender, 10001);
  }

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721, ERC721Enumerable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

  function setManager(address manager_) external override onlyOwner {
    require(manager == address(0), "Manager already set");
    manager = manager_;
  }

  function mint(address recipient, uint256[] memory tokenIds) external override onlyManager {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      _mint(recipient, tokenIds[i]);
    }
  }

  function mint(address[] memory recipients, uint256[] memory tokenIds) external override onlyManager {
    for (uint256 i = 0; i < tokenIds.length; i++) {
      _mint(recipients[i], tokenIds[i]);
    }
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _uri;
  }

  function updateBaseURI(string memory uri) external override onlyOwner {
    // this is mostly an emergency command. Hopefully, we shall not use it
    _uri = uri;
  }
}
