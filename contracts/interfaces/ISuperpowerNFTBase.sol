// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

// Author: Francesco Sullo <francesco@superpower.io>

interface ISuperpowerNFTBase {
  function updateTokenURI(string memory uri) external;

  function freezeTokenURI() external;

  function contractURI() external view returns (string memory);

  function isStaked(uint256 tokenID) external view returns (bool);

  function getStaker(uint256 tokenID) external view returns (address);

  function setPool(address pool) external;

  function removePool(address pool) external;

  function hasStakes(address owner) external view returns (bool);

  function stake(uint256 tokenID) external;

  function unstake(uint256 tokenID) external;

  function unstakeIfRemovedPool(uint256 tokenID) external;
}
