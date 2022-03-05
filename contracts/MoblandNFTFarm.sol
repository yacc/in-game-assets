// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

// Author: Francesco Sullo <francesco@sullo.co>
// Everdragons2 website: https://everdragons2.com

// Modified for Mobland by Superpower Labs Inc.

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IMoblandNFT.sol";

import "hardhat/console.sol";

interface IBlueprintCoupon {
  function burn(uint256 tokenId) external;

  function balanceOf(address owner) external view returns (uint256 balance);

  function tokenOfOwnerByIndex(address owner, uint256 index) external view returns (uint256);
}

contract MoblandNFTFarm is Ownable {
  using ECDSA for bytes32;
  using SafeMath for uint256;

  event ValidatorSet(address validator);

  mapping(bytes32 => address) public usedCodes;
  mapping(address => bool) public claimed;
  address public validator;

  IBlueprintCoupon public coupon;
  IMoblandNFT public nft;

  constructor(
    address nft_,
    address coupon_,
    address validator_
  ) {
    require(nft_.code.length > 0, "Not a contract");
    nft = IMoblandNFT(nft_);
    require(coupon_.code.length > 0, "Not a contract");
    coupon = IBlueprintCoupon(coupon_);
    setValidator(validator_);
  }

  function setValidator(address validator_) public onlyOwner {
    require(validator_ != address(0), "validator cannot be 0x0");
    validator = validator_;
    emit ValidatorSet(validator);
  }

  function claimTokenFromPass(
    bytes32 authCode,
    uint256 tokenId,
    bytes memory signature
  ) external {
    require(tokenId > 0 && tokenId <= 888, "id out of range");
    _mintToken(_msgSender(), authCode, tokenId, signature, 0);
  }

  function recoverLostToken(
    address to,
    bytes32 authCode,
    uint256 tokenId,
    bytes memory signature
  ) external onlyOwner {
    // limited editions from 2 to 9 have been lost
    // due to an error during the batch mint process
    require(tokenId > 1 && tokenId < 10, "id not a lost coupon");
    _mintToken(to, authCode, tokenId, signature, 888);
  }

  function _mintToken(
    address to,
    bytes32 authCode,
    uint256 tokenId,
    bytes memory signature,
    uint256 offset
  ) internal {
    require(to != address(0), "invalid receiver");
    require(usedCodes[authCode] == address(0), "authCode already used");
    require(isSignedByValidator(encodeForSignature(to, authCode, tokenId), signature), "invalid signature");
    usedCodes[authCode] = to;
    nft.mint(to, tokenId + offset);
  }

  function swapTokenFromCoupon(uint256 limit) external {
    uint256 balance = coupon.balanceOf(_msgSender());
    require(balance > 0, "no tokens here");
    if (limit == 0 || limit > balance) {
      // split the process in many steps to not go out of gas
      limit = balance;
    }
    for (uint256 i = balance; i > balance - limit; i--) {
      uint256 tokenId = coupon.tokenOfOwnerByIndex(_msgSender(), i - 1);
      require(tokenId < 2 || (tokenId > 9 && tokenId < 8001), "id out of range");
      nft.mint(_msgSender(), tokenId.add(888));
      coupon.burn(tokenId);
    }
  }

  // the following 2 functions are called internally by _mintToken
  // and externally by the web3 app

  function isSignedByValidator(bytes32 _hash, bytes memory _signature) public view returns (bool) {
    return validator != address(0) && validator == _hash.recover(_signature);
  }

  function encodeForSignature(
    address to,
    bytes32 authCode,
    uint256 tokenId
  ) public view returns (bytes32) {
    return
      keccak256(
        abi.encodePacked(
          "\x19\x01", // EIP-191
          getChainId(),
          to,
          authCode,
          tokenId
        )
      );
  }

  function getChainId() public view returns (uint256) {
    uint256 id;
    assembly {
      id := chainid()
    }
    return id;
  }
}
