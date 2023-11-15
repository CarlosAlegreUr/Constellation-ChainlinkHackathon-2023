// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/token/ERC721/ERC721.sol";
import "@openzeppelin/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/access/manager/AccessManaged.sol";

contract PromptFightersNFT is ERC721, ERC721Enumerable {
    uint256 private _nextTokenId;

    constructor(address initialAuthority) ERC721("PromptFightersNFT", "PFT") {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://ipfs.io";
    }

    function safeMint(address to) public {
        uint256 tokenId = _nextTokenId++;
        tokenId += 1;
        _safeMint(to, tokenId);
    }

    // The following functions are overrides required by Solidity inheritance tree.

    function _update(address to, uint256 tokenId, address auth)
        internal
        override(ERC721, ERC721Enumerable)
        returns (address)
    {
        return super._update(to, tokenId, auth);
    }

    function _increaseBalance(address account, uint128 value) internal override(ERC721, ERC721Enumerable) {
        super._increaseBalance(account, value);
    }

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return super.supportsInterface(interfaceId);
    }
}
