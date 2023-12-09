// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {CcipNftBridge} from "../CcipNftBridge.sol";
import {IPromptFightersCollection} from "../interfaces/IPromptFightersCollection.sol";
import {IFightMatchmaker} from "../interfaces/IFightMatchmaker.sol";

import "../Utils.sol";

import "@openzeppelin/token/ERC721/ERC721.sol";
import {LinkTokenInterface} from "@chainlink/shared/interfaces/LinkTokenInterface.sol";
import {FunctionsClient} from "@chainlink/functions/dev/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";
import {IFunctionsSubscriptions} from "@chainlink/functions/dev/v1_0_0/interfaces/IFunctionsSubscriptions.sol";

/**
 * @title PromptFightersNFT
 * @author PromtFighters team: @CarlosAlegreUr
 * @dev Holds the main NFT collection intended to be only be available
 * for trading only in the Sepolia testnet.
 *
 * @notice This is a POC version with public NFT generation prompts,
 * allowing potential duplication. See the main README for more details
 * on how prompt could be made private as Chainlink Functions improve their features.
 *
 * @notice Minting an NFT requires passing an AI filter trhough Chainlink Functions.
 * This contract also implements CCIP to use your nfts on other chains.
 */
contract PromptFightersNFT is IPromptFightersCollection, ERC721, CcipNftBridge, FunctionsClient {
    using FunctionsRequest for FunctionsRequest.Request;

    //******************************* */
    // CONTRACT'S STATE && CONSTANTS
    //******************************* */

    // Initialized at 1 as nftId is used as the empty value in some systems' logic.
    uint256 private _nextTokenId = 1;

    // On-chain traits
    // Prompt is in bytes, to get human readable do hex-to-string
    // prompt format: descrpition traits separated by "-"
    // desciption is: "name-race-weapon-special skill-fear"
    mapping(uint256 => bytes) private s_nftIdToPrompt;

    // Chainlink Functions Management
    LinkTokenInterface private immutable i_LINK_TOKEN;
    uint64 private immutable i_funcsSubsId;
    bytes32 private immutable i_DON_ID;
    mapping(bytes32 => address) private s_reqIdToUser;

    // CCIP reciever address initialization
    // After the receiver contract is intialized call initReceiverAddress()
    address private CCIP_RECEIVER_CONTRACT;

    //******************** */
    // MODIFIERS
    //******************** */

    /**
     * @dev Makes sure NFTs are not transfered between accounts when
     * they are fighting or not on the chain.
     */
    modifier nftCanBeTraded(uint256 nftId) {
        require(!s_isFighting[nftId], "You cant transfer a fighting NFT.");
        require(s_isOnChain[nftId], "You cant transfer an NFT that is not on this chain.");
        _;
    }

    //******************** */
    // CONSTRUCTOR
    //******************** */

    constructor(address _functionsRouter, uint64 _funcSubsId, address _ccipRouter, IFightMatchmaker _fightMatchmaker)
        ERC721("PromptFightersNFT", "PFT")
        CcipNftBridge(AVL_FUJI_SELECTOR, address(0), _ccipRouter, _fightMatchmaker)
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

    //******************** */
    // PUBLIC FUNCTIONS
    //******************** */

    /**
     * @dev Docs at IPromptFightersCollection.sol
     */
    function safeMint(address _to, string calldata _nftDescriptionPrompt) public contractIsInitialized {
        require(bytes(_nftDescriptionPrompt).length <= 256, "Prompt too large.");
        require(msg.sender == _to, "You can't mint to others.");

        // Call LINK contract transferFrom to fund the Chainlink Functions call.
        // Amount is arbitrary now but on Sepolia tests so far it costs around 0.25 LINK.
        uint256 amount = 0.5 ether;
        // bool success = i_LINK_TOKEN.transferFrom(msg.sender, address(this), amount);
        bool success =
            i_LINK_TOKEN.transferAndCall(ETH_SEPOLIA_FUNCTIONS_ROUTER, amount, abi.encode(ETH_SEPOLIA_FUNCS_SUBS_ID));
        require(success, "Fail funding LINK");

        // Calls Chainlink Funcs, they call GPT to see if the NFT is not too overpowered
        // if not they mint it in the callback function.
        _validateAndMintNft(_nftDescriptionPrompt);
    }

    // @dev The following functions are only overriden to add the nfCanBeTraded modifier.

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
     * @dev It finally mints the NFT after calling ChainlinkFunctions which deems
     * the promt's validity trhough OpenAI's API.
     *
     * @notice Deemed invalid prompts are returned as a string with one blank space -> " ".
     *
     * @param response If its a success the prompt the user wrote is saved here as a string
     * if not its just an empty string.
     * @param err If ther is an exeution error it will be sent here.
     */
    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
        // NOTE: For some reason when there is not an error err.length > 0.
        // Thus we make invalid prompts return an empty string.
        if (keccak256(response) != keccak256(" ")) {
            if (s_reqIdToUser[requestId] != address(0)) {
                uint256 tokenId = _nextTokenId;
                _nextTokenId++;

                // Special traits on-chain
                s_isOnChain[tokenId] = true;
                _safeMint(s_reqIdToUser[requestId], tokenId);

                s_nftIdToPrompt[tokenId] = response;
                emit PromptFighters__NftMinted(ownerOf(tokenId), tokenId, response, err, block.timestamp);
            }
        } else {
            emit PromptFighters__MintingNftDeemedInvalid(s_reqIdToUser[requestId], requestId, block.timestamp);
        }
        delete s_reqIdToUser[requestId];
    }

    //******************** */
    // PRIVATE FUNCTIONS
    //******************** */

    /**
     * @dev Calls Chainlink Functions to validate the prompt and mint the NFT.
     */
    function _validateAndMintNft(string calldata _nftPrompt) private {
        string[] memory arg = new string[](1);
        arg[0] = _nftPrompt;

        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(NFT_GENERATION_SCRIPT_MOCK);
        req.setArgs(arg); // Arg is the NFT prompt

        // TODO: Add git secrets url for for GPT-API key

        bytes32 lastRequestId = _sendRequest(req.encodeCBOR(), i_funcsSubsId, GAS_LIMIT_NFT_GENERATION, i_DON_ID);

        s_reqIdToUser[lastRequestId] = msg.sender;
    }

    //************************ */
    // VIEW / PURE FUNCTIONS
    //************************ */

    //************************ */
    // GETTERS
    //************************ */

    /**
     * @dev Docs at ICcipNftBridge.sol
     */
    function getPromptOf(uint256 _nftId)
        public
        view
        override(CcipNftBridge, IPromptFightersCollection)
        returns (string memory)
    {
        return string(s_nftIdToPrompt[_nftId]);
    }

    /**
     * @dev Docs at ICcipNftBridge.sol
     */
    function getOwnerOf(uint256 _nftId) public view override returns (address) {
        return ownerOf(_nftId);
    }

    function getNftIdToPrompt(uint256 nftId) public view returns (bytes memory) {
        return s_nftIdToPrompt[nftId];
    }

    function getLinkTokenInterface() public view returns (address) {
        return address(i_LINK_TOKEN);
    }

    function getFuncsSubsId() public view returns (uint64) {
        return i_funcsSubsId;
    }

    function getDonId() public view returns (bytes32) {
        return i_DON_ID;
    }

    function getReqIdToUser(bytes32 reqId) public view returns (address) {
        return s_reqIdToUser[reqId];
    }

    function getCcipReceiverContract() public view returns (address) {
        return CCIP_RECEIVER_CONTRACT;
    }

    //************************************** */
    // VIRTUAL FUNCS NOT USED IN THIS CHAIN
    //************************************** */

    // The following functions are inherited from CcipNftBridge and are mainly
    // needed in chains that don't have the official collection. So in main-chain they
    // just do nothing.

    function _updateNftStateOnSendChainSpecifics(uint256 _nftId) internal override {}

    function _updateNftStateOnReceiveChainSpecifics(uint256 _nftId, address _owner, string memory _prompt)
        internal
        override
    {}

    function _setOwnerOf(uint256 _nftId, address _owner) internal override {}
    function _setPromptOf(uint256 _nftId, string memory _prompt) internal override {}

    //**************************** */
    // INHERITANCE TREE AMBIGUITIES
    //**************************** */

    // The following functions are overrides required by Solidity inheritance tree.

    function supportsInterface(bytes4 interfaceId)
        public
        view
        /*virtual*/
        override(ERC721, CcipNftBridge)
        returns (bool)
    {
        return ERC721.supportsInterface(interfaceId) || CcipNftBridge.supportsInterface(interfaceId);
    }
}
