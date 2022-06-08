// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

// Authors: Francesco Sullo <francesco@superpower.io>
// (c) Superpower Labs Inc

interface ISuperpowerNFT {
  function setMaxSupply(uint256 maxSupply_) external;

  function setMinter(address minter_, bool enabled) external;

  function mint(address recipient, uint256 amount) external;

  function endMinting() external;

  function mintEnded() external view returns (bool);

  function maxSupply() external view returns (uint256);

  function nextTokenId() external view returns (uint256);
}
