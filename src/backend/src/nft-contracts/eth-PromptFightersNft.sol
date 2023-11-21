// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ICcipNftBridge} from "../interfaces/ICcipNftBridge.sol";

import "@openzeppelin/token/ERC721/ERC721.sol";
import "@openzeppelin/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/access/manager/AccessManaged.sol";
import {FunctionsClient} from "@chainlink/functions/dev/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";
import {IRouterClient} from "@chainlink-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {OwnerIsCreator} from "@chainlink-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {Client} from "@chainlink-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";

// Mint process
// Encript prompt, secrets is the prompt, hash from blockchain, script checks validity and then calls chatGPT-API
// Drawbacks, evey person you battle against can get information about your prompt and can copy it.
// TODO: MAKE SURE THE USER CANT DO ANYTHING WITH THE NFT WHILE HE IS IN BATTLE
contract PromptFightersNFT is ERC721, ERC721Enumerable, CCIPReceiver, ICcipNftBridge, FunctionsClient {
    using FunctionsRequest for FunctionsRequest.Request;

    uint256 private _nextTokenId = 1;
    bytes private constant s_NFTGenerationDenoFile = "";

    // On-chain traits
    mapping(uint256 => bool) private s_winsCount;
    mapping(uint256 => bool) private s_losesCount;

    // CCIP nft tracking
    mapping(uint256 => bool) private s_canMove;
    mapping(uint256 => bool) private s_isOnChain;

    constructor(address _functionsRouter, address _ccipRouter)
        ERC721("PromptFightersNFT", "PFT")
        FunctionsClient(_functionsRouter)
        CCIPReceiver(_ccipRouter)
    {}

    // IPFS gateway or whatever service we use for storing the image.
    // The NFT traits will be: hash of prompt, DALL-3 image
    function _baseURI() internal pure override returns (string memory) {
        return "https://ipfs.io";
    }

    // Call chainlink functions here to verify prompt
    function safeMint(address to) public {
        require(msg.sender == to, "You can't mint to others.");
        uint256 tokenId = _nextTokenId;
        _nextTokenId++;
        _safeMint(to, tokenId);
        s_isOnChain[tokenId] = true;
        s_canMove[tokenId] = true;
    }

    // Chainlink functions for NFT generation
    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal virtual override {}

    // CCIP
    // Senders
    function sendNft(uint256 nftId) external {}

    function isNftOnChain(uint256 nftId) external returns (bool) {}

    // Set by Chainlink CCIP
    // Set nft on chain
    function _ccipReceive(Client.Any2EVMMessage memory message) internal virtual override {}

    // The following functions are overrides required by Solidity inheritance tree.
    function supportsInterface(bytes4 interfaceId)
        public
        pure // TODO: it was view before check if this is correct
        virtual
        override(ERC721, ERC721Enumerable, CCIPReceiver)
        returns (bool)
    {}

    function _increaseBalance(address account, uint128 value) internal virtual override(ERC721, ERC721Enumerable) {}

    function _update(address to, uint256 tokenId, address auth)
        internal
        virtual
        override(ERC721, ERC721Enumerable)
        returns (address)
    {}
}
