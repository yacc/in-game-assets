// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

import "@ndujalabs/erc721playable/contracts/IERC721Playable.sol";

// Authors: Francesco Sullo <francesco@superpower.io>
// (c) Superpower Labs Inc

interface ISuperpowerNFT {
  function setMaxSupply(uint256 maxSupply_) external;

  function setFarmer(address farmer_, bool enabled) external;

  function mint(address recipient, uint256 amount) external;

  function mintInitAndFill(
    address to,
    address player,
    uint8[31] memory initialAttributes
  ) external;

  function mintAndInit(address to, uint256 amount) external;

  function endMinting() external;

  function mintEnded() external view returns (bool);

  function maxSupply() external view returns (uint256);

  function nextTokenId() external view returns (uint256);
}
