// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

contract CouponMock is ERC721, ERC721Enumerable {
  constructor() ERC721("Syn City Blueprint Coupons", "SYNBC") {}

  function safeMint(address to, uint256 tokenId) public {
    _safeMint(to, tokenId);
  }

  function burn(uint256 tokenId) public virtual {
    _burn(tokenId);
  }

  // The following functions are overrides required by Solidity.

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
}
