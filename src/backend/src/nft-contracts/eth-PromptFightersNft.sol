// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {CcipNftBridge} from "../CcipNftBridge.sol";
import {IPromptFightersCollection} from "../interfaces/IPromptFightersCollection.sol";
import {IFightMatchmaker} from "../interfaces/IFightMatchmaker.sol";
import {Initializable} from "../Initializable.sol";

import "../Utils.sol";

import "@openzeppelin/token/ERC721/ERC721.sol";
import {LinkTokenInterface} from "@chainlink/shared/interfaces/LinkTokenInterface.sol";
import {FunctionsClient} from "@chainlink/functions/dev/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";
import {IFunctionsSubscriptions} from "@chainlink/functions/dev/v1_0_0/interfaces/IFunctionsSubscriptions.sol";
import {IRouterClient} from "@chainlink-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {OwnerIsCreator} from "@chainlink-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {Client} from "@chainlink-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";

import "forge-std/console.sol";

/**
 * @title PromptFightersNFT
 * @author PromtFighters team: Carlos
 * @dev Holds the main NFT collection intended to be only be available
 * for trading only in the ETHEREUM mainnnet and testnets.
 *
 * @notice This is a POC version with public NFT generation prompts,
 * allowing potential duplication.
 *
 * @notice Minting an NFT requires passing an AI filter trhough Chainlink Functions
 * and this contract also implements CCIP to use your nfts to fight on other chains.
 * In this case only Fuji Avalanche testnet is allowed.
 */
contract PromptFightersNFT is IPromptFightersCollection, ERC721, CcipNftBridge, FunctionsClient {
    using FunctionsRequest for FunctionsRequest.Request;

    // Initialized at 1 as nftId is used as the empty value in some systems' logic.
    uint256 public _nextTokenId = 1;

    // On-chain traits
    // Prompt is in bytes, to get human readable do hex-to-string
    // prompt format: descrpition traits separated by "-"
    mapping(uint256 => bytes) public s_nftIdToPrompt;

    // Chainlink Functions Management
    LinkTokenInterface private immutable i_LINK_TOKEN;
    uint64 private immutable i_funcsSubsId;
    bytes32 private immutable i_DON_ID;
    mapping(bytes32 => address) public s_reqIdToUser;

    // CCIP reciever address initialization
    // to connect the briged contracts one must be deployed first and the other one
    // later, for safer deployment we add this state variables.
    address CCIP_RECEIVER_CONTRACT;

    constructor(address _functionsRouter, uint64 _funcSubsId, address _ccipRouter, IFightMatchmaker _fightMatchmaker)
        ERC721("PromptFightersNFT", "PFT")
        CcipNftBridge(ETH_SEPOLIA_SELECTOR, address(0), _ccipRouter, _fightMatchmaker)
        FunctionsClient(_functionsRouter)
    {
        require(_ccipRouter == ETH_SEPOLIA_CCIP_ROUTER, "Incorrect router.");

        i_LINK_TOKEN = block.chainid == ETH_SEPOLIA_CHAIN_ID
            ? LinkTokenInterface(ETH_SEPOLIA_LINK)
            : LinkTokenInterface(AVL_FUJI_LINK);
        i_DON_ID = block.chainid == ETH_SEPOLIA_CHAIN_ID ? ETH_SEPOLIA_DON_ID : AVL_FUJI_DON_ID;

        i_funcsSubsId = _funcSubsId;

        // @dev Doesn't work, needs to accept TermsOfService first, so far this is only
        // possible trhough Chainlink's API.
        // IFunctionsSubscriptions(_functionsRouter).createSubscription();
        // IFunctionsSubscriptions(_functionsRouter).addConsumer(i_funcsSubsId, address(this));
    }

    /**
     * @dev Makes sure NFTs are not transfered between accounts when
     * they are fighting or not in the chain. This is for simpler ownership
     * tracking accross chains and avoid sending bets bugs.
     */
    modifier nftCanBeTraded(uint256 nftId) {
        require(!s_isFighting[nftId], "You cant transfer a fighting NFT.");
        require(s_isOnChain[nftId], "You cant transfer an NFT that is not on this chain.");
        _;
    }

    //******************** */
    // PUBLIC FUNCTIONS
    //******************** */

    /**
     * @dev Docs at IPromptFightersCollection.sol
     */
    function safeMint(address _to, string calldata _nftDescriptionPrompt) public contractIsInitialized {
        require(bytes(_nftDescriptionPrompt).length <= 256, "Prompt too large.");
        require(msg.sender == _to, "You can't mint to others.");

        // Call LINK contract transferFrom
        uint256 amount = 0.5 ether;
        bool success = i_LINK_TOKEN.transferFrom(msg.sender, address(this), amount);
        require(success, "Fail funding LINK");

        // Calls Chainlink Funcs, they call GPT to see if the NFT is not too overpowered
        // if not they mint it in the callback function.
        _validateAndMintNft(_nftDescriptionPrompt);
    }

    // The following functions are only overriden to make sure that when an NFT is
    // fighting or not in the chain, that NFT can't be traded between addresses.

    function transferFrom(address _from, address _to, uint256 _tokenId)
        public
        override(ERC721)
        nftCanBeTraded(_tokenId)
    {
        ERC721.transferFrom(_from, _to, _tokenId);
    }

    function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data)
        public
        override(ERC721)
        nftCanBeTraded(_tokenId)
    {
        ERC721.safeTransferFrom(_from, _to, _tokenId, _data);
    }

    //******************** */
    // INTERNAL FUNCTIONS
    //******************** */

    /**
     * @dev Don't enter the link. ;D
     */
    function _baseURI() internal pure override returns (string memory) {
        return "https://www.youtube.com/watch?v=dQw4w9WgXcQ";
    }

    /**
     * @dev It finally mints the NFT after calling ChainlinkFunctions.
     *
     * @param response If its a success the prompt the user wrote is saved here as a string.
     * @param err If ther is an error it means ChatGPT deemd the NFT invalid.
     */

    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
        // For some reason when there is an error err.length > 0. TODO: figure out how to no enter
        // this "if" when error ocures
        if (s_reqIdToUser[requestId] != address(0)) {
            uint256 tokenId = _nextTokenId;
            _nextTokenId++;

            // Special traits on-chain
            s_isOnChain[tokenId] = true;
            _safeMint(s_reqIdToUser[requestId], tokenId);

            s_nftIdToPrompt[tokenId] = response;
            emit PromptFighters__NftMinted(ownerOf(tokenId), tokenId, response, err, block.timestamp);
        }
        delete s_reqIdToUser[requestId];
    }

    //******************** */
    // PRIVATE FUNCTIONS
    //******************** */

    function _validateAndMintNft(string calldata _nftPrompt) private {
        string[] memory arg = new string[](1);
        arg[0] = _nftPrompt;

        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(NFT_GENERATION_SCRIPT_MOCK);
        req.setArgs(arg); // Args are NFT prompts.

        // TODO: Add url for GPT-API

        bytes32 lastRequestId = _sendRequest(req.encodeCBOR(), i_funcsSubsId, GAS_LIMIT_NFT_GENERATION, i_DON_ID);

        s_reqIdToUser[lastRequestId] = msg.sender;
    }

    //************************ */
    // VIEW / PURE FUNCTIONS
    //************************ */

    function getPromptOf(uint256 _nftId)
        public
        view
        override(CcipNftBridge, IPromptFightersCollection)
        returns (string memory)
    {
        return abi.decode(s_nftIdToPrompt[_nftId], (string));
    }

    function getOwnerOf(uint256 _nftId) public view override returns (address) {
        return ownerOf(_nftId);
    }

    // TODO: ceck if needed more getters

    //**************************** */
    // INHERITANCE TREE AMBIGUITIES
    //**************************** */

    // The following functions are overrides required by Solidity inheritance tree.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        /*virtual*/
        override(ERC721, CCIPReceiver)
        returns (bool)
    {
        return ERC721.supportsInterface(interfaceId) || CCIPReceiver.supportsInterface(interfaceId);
    }

    // The following functions are inherited from CcipNftBridge and are only
    // needed in chains that don't have the official collection. So in main-chain they
    // just do nothing.

    function _updateNftStateOnSend(uint256 _nftId) internal override {}
    function _updateNftStateOnReceive(uint256 _nftId, address _owner, string memory _prompt) internal override {}
    function setOwnerOf(uint256 _nftId, address _owner) internal override {}
    function setPromptOf(uint256 _nftId, string memory _prompt) internal override {}
}
