// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ICcipNftBridge} from "../interfaces/ICcipNftBridge.sol";
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
contract PromptFightersNFT is
    IPromptFightersCollection,
    ERC721,
    CCIPReceiver,
    ICcipNftBridge,
    FunctionsClient,
    Initializable
{
    using FunctionsRequest for FunctionsRequest.Request;

    // Initialized at 1 as nftId is used as the empty value in some systems' logic.
    uint256 private _nextTokenId = 1;

    // On-chain traits
    mapping(uint256 => string) s_nftIdToPrompt;
    // @notice Commented out to simplify POC
    // mapping(uint256 => bool) private s_winsCount;
    // mapping(uint256 => bool) private s_losesCount;

    // Contracts that call this contract
    IFightMatchmaker immutable i_FIGHT_MATCHMAKER;

    // Chainlink Functions Management
    LinkTokenInterface private immutable i_LINK_TOKEN;
    uint64 private immutable i_funcsSubsId;
    bytes32 private immutable i_DON_ID;
    mapping(bytes32 => address) s_reqIdToUser;

    // CCIP nft tracking (TODO: these could be simplified as an enum in ccip nft bridge interface)
    // canMove is false if the NFT is fighting
    mapping(uint256 => bool) private s_isFighting;
    mapping(uint256 => bool) private s_isOnChain;

    // CCIP reciever address initialization
    // to connect the briged contracts one must be deployed first and the other one
    // later, for safer deployment we add this state variables.
    address CCIP_RECEIVER_CONTRACT;

    constructor(address _functionsRouter, uint64 _funcSubsId, address _ccipRouter, IFightMatchmaker _fightMatchmaker)
        ERC721("PromptFightersNFT", "PFT")
        FunctionsClient(_functionsRouter)
        CCIPReceiver(_ccipRouter)
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

        i_FIGHT_MATCHMAKER = _fightMatchmaker;
    }

    /**
     * @dev 1 time use function. Initializes the CCIP receiver contract addresses
     * and blocks this same function use forever and unlocks all the functionalities
     * of the contract.
     *
     * @notice Can only be called by INTIALIZER_ADDRESS.
     * @notice A 2 step setting process would be safer, one for proposing the address
     * and one for confirming it and then indeed lock the setter forever. But this is
     * a simple PoC.
     */
    function initializeReceiver(address _receiver) external initializeActions {
        CCIP_RECEIVER_CONTRACT = _receiver;
    }

    /**
     * @dev Checks for:
     *  - Correct destination chain.
     *  - Correct receiver contract.
     *  - Owner of NFT is the one moving it.
     *
     * Also updates canMove and isOnChain states for that NFT.
     */
    modifier sendNftCrossChainActions(uint64 destinationChainSelector, address receiver, string calldata nftId) {
        uint256 _nftId = _stringToUint(nftId);
        require(ownerOf(_nftId) == msg.sender, "You are not the owner.");

        require(destinationChainSelector == AVL_FUJI_SELECTOR, "We only support Fuji testnet NFT transfers.");
        require(receiver == CCIP_RECEIVER_CONTRACT, "Thats not the receiver contract.");

        require(!s_isFighting[_nftId], "Nft is bussy can't move.");
        require(s_isOnChain[_nftId], "Nft is not currently in this chain.");

        delete s_isOnChain[_nftId];
        delete s_isFighting[_nftId];
        _;
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

    /**
     * @dev Only FightMatchmaker contract can call.
     */
    modifier onlyMatchmaker() {
        require(msg.sender == address(i_FIGHT_MATCHMAKER), "Only FightMatchmaker can call this function");
        _;
    }

    //******************** */
    // EXTERNAL FUNCTIONS
    //******************** */

    /**
     * @dev Docs at ICcipNftBridge.sol
     */
    function sendNft(uint64 _destinationChainSelector, address _receiver, string calldata _nftId)
        external
        payable
        contractIsInitialized
        sendNftCrossChainActions(_destinationChainSelector, _receiver, _nftId)
        returns (bytes32 messageId)
    {
        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(_receiver, _nftId, address(0));

        // Initialize a router client instance to interact with cross-chain router
        IRouterClient router = IRouterClient(this.getRouter());

        // Get the fee required to send the CCIP message
        uint256 fees = router.getFee(_destinationChainSelector, evm2AnyMessage);
        require(fees <= msg.value, "Not enought ETH sent.");

        // Send the CCIP message through the router and store the returned CCIP message ID
        messageId = router.ccipSend{value: fees}(_destinationChainSelector, evm2AnyMessage);

        // Emit an event with message details
        emit ICCIPNftBridge__NftSent(msg.sender, AVL_FUJI_SELECTOR, _nftId, block.timestamp);

        // Return the CCIP message ID
        return messageId;
    }

    function setIsNftFighting(uint256 nftId, bool isFightihng) external onlyMatchmaker {
        s_isFighting[nftId] = isFightihng;
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
        if (err.length > 0 && s_reqIdToUser[requestId] != address(0)) {
            uint256 tokenId = _nextTokenId;
            _nextTokenId++;

            // Special traits on-chain
            s_isOnChain[tokenId] = true;
            _safeMint(s_reqIdToUser[requestId], tokenId);

            // Decode prompt from response TODO I'm not sure if this is the right way
            string memory prompt = abi.decode(response, (string));
            s_nftIdToPrompt[tokenId] = prompt;
            emit PromptFighters__NftMinted(ownerOf(tokenId), tokenId);
        }
        delete s_reqIdToUser[requestId];
    }

    /**
     * @dev Internal function used in sendNft() to send the message to other chains wit CCIP.
     */
    function _ccipReceive(Client.Any2EVMMessage memory _message) internal /*virtual*/ override {
        // decode nftid from message and mark it as onChain
        require(_message.sourceChainSelector == AVL_FUJI_SELECTOR, "We only accept messages from Fuji.");

        string memory nftId = abi.decode(_message.data, (string)); // abi-decoding of the sent text
        uint256 nftIdInt = _stringToUint(nftId);
        s_isOnChain[nftIdInt] = true;
        delete s_isFighting[nftIdInt]; // Set to false
        emit ICCIPNftBridge__NftReceived(ownerOf(nftIdInt), ETH_SEPOLIA_CHAIN_ID, nftIdInt, block.timestamp);
    }

    /**
     * @dev Builds the CCIP message struct to send.
     */
    function _buildCCIPMessage(address _receiver, string calldata _text, address _feeTokenAddress)
        internal
        pure
        returns (Client.EVM2AnyMessage memory)
    {
        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        return Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver), // ABI-encoded receiver address
            data: abi.encode(_text), // ABI-encoded string
            tokenAmounts: new Client.EVMTokenAmount[](0), // Empty array aas no tokens are transferred
            extraArgs: Client._argsToBytes(
                // Additional arguments, setting gas limit and non-strict sequencing mode
                Client.EVMExtraArgsV1({gasLimit: 200_000, strict: false})
                ),
            // Set the feeToken to a feeTokenAddress, indicating specific asset will be used for fees
            feeToken: _feeTokenAddress
        });
    }

    //******************** */
    // PRIVATE FUNCTIONS
    //******************** */

    function _validateAndMintNft(string calldata _nftPrompt) private {
        string[] memory arg = new string[](1);
        arg[0] = _nftPrompt;

        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(NFT_GENERATION_SCRIPT);
        req.setArgs(arg); // Args are NFT prompts.

        bytes32 lastRequestId = _sendRequest(req.encodeCBOR(), i_funcsSubsId, GAS_LIMIT_NFT_GENERATION, i_DON_ID);

        s_reqIdToUser[lastRequestId] = msg.sender;
    }

    // Made by chatGPT hope it works :d
    function _stringToUint(string memory _s) private pure returns (uint256) {
        bytes memory b = bytes(_s);
        uint256 result = 0;
        for (uint256 i = 0; i < b.length; i++) {
            if (b[i] >= 0x30 && b[i] <= 0x39) {
                result = result * 10 + (uint256(uint8(b[i])) - 48);
            } else {
                // Character is not a number, revert
                revert("Invalid input string");
            }
        }
        return result;
    }

    //************************ */
    // VIEW / PURE FUNCTIONS
    //************************ */

    function getPrompt(uint256 _nftId) external view returns (string memory) {
        return s_nftIdToPrompt[_nftId];
    }

    function isNftOnChain(uint256 nftId) external view returns (bool) {
        return s_isOnChain[nftId];
    }

    function getOwnerOf(uint256 _nftId) public view returns (address) {
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
}
