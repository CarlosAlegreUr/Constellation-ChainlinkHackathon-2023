// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ICcipNftBridge} from "../interfaces/ICcipNftBridge.sol";
import {IPromptFightersCollection} from "../interfaces/IPromptFightersCollection.sol";

import "../Utils.sol";

import "@openzeppelin/token/ERC721/ERC721.sol";
import "@openzeppelin/token/ERC721/extensions/ERC721Enumerable.sol";
import {FunctionsClient} from "@chainlink/functions/dev/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";
import {IRouterClient} from "@chainlink-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {OwnerIsCreator} from "@chainlink-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {Client} from "@chainlink-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";

// TODO: MAKE SURE THE USER CANT DO ANYTHING WITH THE NFT WHILE HE IS IN BATTLE
/**
 * @title PromptFightersNFT
 * @author PromtFighters team: Carlos
 * @dev This is the contract that holds the main NFT collection intended to be only be available
 * for trading only in the ETHEREUM mainnnet and testnets.
 *
 * @notice This is a simplified version where prompts that generate the NFTs are public.
 * So anyone can copy you.
 *
 * The advanced design would involve saving just the hash of the prompt. But then for assuring
 * that Chainlink Functions can corroborate the authenticity of your prompt it would require
 * the deno file to execute advanced hash functions, which yet can't do or its very complex due
 * to Functions being in beta and uncapable of importing useful libraries like hash implementing
 * ones or asymetric encryption ones.
 *
 * In this advanced design only the node in the DON would see your prompt but they are assumed to
 * be trusted and only small parts of your character would be visible by other players you fight against
 * making copying your NFT exactly too hard.
 */
contract PromptFightersNFT is
    IPromptFightersCollection,
    ERC721,
    ERC721Enumerable,
    CCIPReceiver,
    ICcipNftBridge,
    FunctionsClient
{
    using FunctionsRequest for FunctionsRequest.Request;

    uint256 private _nextTokenId = 1;
    bytes private constant s_NFTGenerationDenoFile = "";

    // On-chain traits
    mapping(uint256 => string) s_nftIdToPrompt;
    mapping(uint256 => bool) private s_winsCount;
    mapping(uint256 => bool) private s_losesCount;

    // Chainlink Functions filter
    mapping(bytes32 => address) s_reqIdToUser;

    // CCIP nft tracking
    mapping(uint256 => bool) private s_canMove;
    mapping(uint256 => bool) private s_isOnChain;

    constructor(address _functionsRouter, address _ccipRouter)
        ERC721("PromptFightersNFT", "PFT")
        FunctionsClient(_functionsRouter)
        CCIPReceiver(_ccipRouter)
    {}

    //******************** */
    // EXTERNAL FUNCTIONS
    //******************** */

    // CCIP
    // Senders
    function sendNft(uint256 nftId) external {}

    function isNftOnChain(uint256 nftId) external returns (bool) {
        return s_isOnChain[nftId];
    }

    //******************** */
    // PUBLIC FUNCTIONS
    //******************** */

    /**
     * @dev Before minting the promt, it must pass an AI filter so as to the
     * NFTs are interesting to play with and don't violate any copyright or ethical
     * rules OpenAI has.
     * 
     * @notice Before minting you must approve this contract to use 0.5 LINK to pass the filter.
     * In the future the amounts should be calculated and tested to asses fair prices covering
     * Chainlink Functions and OpenAI's API.
     */
    function safeMint(address _to, string calldata _nftDescriptionPrompt) public {
        require(msg.sender == _to, "You can't mint to others.");

        // Call LINK contract transferFrom
        // uint256 amount = 0.5 ether;
        // bool success = i_LINK_TOKEN.transferFrom(msg.sender, address(this), amount);
        // require(success, "Fail funding LINK");

        // Calls Chainlink Funcs, they call GPT to see if the NFT is not too overpowered
        // if not they mint it in the callback function.
        bytes32 reqId = _validateAndMintNft(_nftDescriptionPrompt);
        s_reqIdToUser[reqId] = msg.sender;
    }

    //******************** */
    // INTERNAL FUNCTIONS
    //******************** */

    // TODO: do we have time to implement the image?
    // IPFS gateway or whatever service we use for storing the image.
    // The NFT traits will be: hash of prompt, DALL-3 image
    function _baseURI() internal pure override returns (string memory) {
        return "https://ipfs.io";
    }

    // Chainlink functions for NFT generation
    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
        if (err.length > 0) {
            uint256 tokenId = _nextTokenId;
            _nextTokenId++;

            // Special traits on-chain
            s_isOnChain[tokenId] = true;
            s_canMove[tokenId] = true;
            _safeMint(s_reqIdToUser[requestId], tokenId);

            // Decode from response prompt and image location
            // s_nftIdToPrompt[tokenId] = PROMPT;
        }
        delete s_reqIdToUser[requestId];
    }

    // Set by Chainlink CCIP
    // Set nft on chain
    function _ccipReceive(Client.Any2EVMMessage memory message) internal virtual override {
        // decode nftid from message and mark it as onChain
    }

    //******************** */
    // PRIVATE FUNCTIONS
    //******************** */

    function _validateAndMintNft(string calldata _nftPrompt) private returns (bytes32) {
        // TODO: adapt paramters needed for validating NFTs
        // FunctionsRequest.Request memory req;
        // req.initializeRequestForInlineJavaScript(_cfParam.source);
        // req.addSecretsReference(_cfParam.encryptedSecretsUrls);
        // if (_cfParam.args.length > 0) req.setArgs(_cfParam.args); // Args are NFT prompts.

        bytes32 lastRequestId;
        // = _sendRequest(req.encodeCBOR(), i_funcsSubsId, GAS_LIMIT_FIGHT_GENERATION, i_DON_ID);

        // s_requestsIdToFightId[lastRequestId] = _fightId;
        // s_reqIsValid[lastRequestId] = true;
        // s_requestsIdToUser[lastRequestId] = msg.sender;
        return lastRequestId;
    }

    //************************ */
    // VIEW / PURE FUNCTIONS
    //************************ */
    function getPrompt(uint256 _nftId) external returns (string memory) {
        return s_nftIdToPrompt[_nftId];
    }

    //**************************** */
    // INHERITANCE TREE AMBIGUITIES
    //**************************** */

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
