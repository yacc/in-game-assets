// SPDX-License-Identifier: MIT
pragma solidity 0.8.11;

// Authors: Francesco Sullo <francesco@sullo.co>
//          Emanuele Cesena <emanuele@ndujalabs.com>
// Everdragons2, https://everdragons2.com

// Modified for Mobland by Superpower Labs Inc.

import "@ndujalabs/erc721playable/contracts/ERC721PlayableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";
import "@ndujalabs/wormhole721/contracts/Wormhole721Upgradeable.sol";

import "./interfaces/IMoblandNFT.sol";

//import "hardhat/console.sol";

contract MoblandNFT is
  IMoblandNFT,
  Initializable,
  ERC721Upgradeable,
  ERC721PlayableUpgradeable,
  ERC721EnumerableUpgradeable,
  Wormhole721Upgradeable
{
  bool private _mintEnded;
  bool private _baseTokenURIFrozen;
  string private _baseTokenURI;
  address public manager;
  uint256 public nextTokenId;
  uint256 public reservedMaxTokenId;

  modifier onlyManager() {
    require(manager != address(0) && _msgSender() == manager, "Forbidden");
    _;
  }

  modifier canMint() {
    require(!_mintEnded, "Minting ended");
    _;
  }

  /// @custom:oz-upgrades-unsafe-allow constructor
  constructor() initializer {}

  function initialize(
    string memory name,
    string memory symbol,
    string memory tokenUri
  ) public initializer {
    __Wormhole721_init(name, symbol);
    __ERC721Enumerable_init();
    _baseTokenURI = tokenUri;
  }

  function startDistribution(uint256 nextTokenId_) external onlyOwner {
    require(nextTokenId_ > 0, "next token Id cannot be zero");
    nextTokenId = nextTokenId_;
    reservedMaxTokenId = nextTokenId_ - 1;
  }

  function _authorizeUpgrade(address newImplementation) internal override onlyOwner {}

  function _beforeTokenTransfer(
    address from,
    address to,
    uint256 tokenId
  ) internal override(ERC721Upgradeable, ERC721PlayableUpgradeable, ERC721EnumerableUpgradeable) {
    super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(Wormhole721Upgradeable, ERC721Upgradeable, ERC721PlayableUpgradeable, ERC721EnumerableUpgradeable)
    returns (bool)
  {
    return super.supportsInterface(interfaceId);
  }

  function setManager(address manager_) external override onlyOwner canMint {
    require(manager_.code.length > 0, "Not a contract");
    manager = manager_;
  }

  function mint(address recipient, uint256 tokenId) public override onlyManager canMint {
    if (tokenId == 0) {
      // get next not-reserved available
      tokenId = nextTokenId++;
    } else {
      require(tokenId <= reservedMaxTokenId, "Token id our of range");
    }
    _safeMint(recipient, tokenId);
  }

  function endMinting() external override onlyOwner {
    _mintEnded = true;
  }

  function mintEnded() external view override returns (bool) {
    return _mintEnded;
  }

  function _baseURI() internal view virtual override returns (string memory) {
    return _baseTokenURI;
  }

  function updateTokenURI(string memory uri) external override onlyOwner {
    require(!_baseTokenURIFrozen, "baseTokenUri has been frozen");
    // after revealing, this allows to set up a final uri, if useful
    _baseTokenURI = uri;
  }

  function freezeTokenURI() external override onlyOwner {
    _baseTokenURIFrozen = true;
  }

  function contractURI() public view returns (string memory) {
    return string(abi.encodePacked(_baseTokenURI, "0"));
  }
}
