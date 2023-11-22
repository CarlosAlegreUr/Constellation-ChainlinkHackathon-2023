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
    // @notice Commented out to simplify POC
    // mapping(uint256 => bool) private s_winsCount;
    // mapping(uint256 => bool) private s_losesCount;

    // Chainlink Functions filter
    mapping(bytes32 => address) s_reqIdToUser;

    // CCIP nft tracking
    mapping(uint256 => bool) private s_canMove;
    mapping(uint256 => bool) private s_isOnChain;

    // CCIP recever address initialization
    bool s_isInitializedLock;
    address RECEIVER_CONTRACT;
    // This must be a contract owned by deployer and immediately called before contract is used.
    address constant INTIALIZER_ADDRESS = address(777);

    constructor(address _functionsRouter, address _ccipRouter)
        ERC721("PromptFightersNFT", "PFT")
        FunctionsClient(_functionsRouter)
        CCIPReceiver(_ccipRouter)
    {}

    modifier sendNftCrossChainActions(uint64 destinationChainSelector, address receiver, string calldata nftId) {
        uint256 _nftId = _stringToUint(nftId);
        require(ownerOf(_nftId) == msg.sender, "You are not the owner.");

        require(destinationChainSelector == AVL_FUJI_SELECTOR, "We only support Fuji testnet NFT transfers.");
        require(receiver == RECEIVER_CONTRACT, "Thats not the receiver contract.");

        require(s_canMove[_nftId], "Nft is bussy can't move.");

        require(s_isOnChain[_nftId], "Nft is not currently in this chain.");

        _;

        s_isOnChain[_nftId] = false;
        s_canMove[_nftId] = false;
    }

    modifier contractIsInitialized() {
        require(s_isInitializedLock, "Contract is not initialized.");
        _;
    }

    //******************** */
    // EXTERNAL FUNCTIONS
    //******************** */

    // CCIP

    /// @notice Sends data to receiver on the destination chain.
    /// @notice Pay for fees in native gas.
    /// @dev Assumes your contract has sufficient native gas tokens.
    /// @param _destinationChainSelector The identifier (aka selector) for the destination blockchain.
    /// @param _receiver The address of the recipient on the destination blockchain.
    /// @param _nftId The text to be sent.
    /// @return messageId The ID of the CCIP message that was sent.
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

    function initializeReceiver(address _receiver) external {
        require(!s_isInitializedLock, "Contract already intialized.");
        require(msg.sender == INTIALIZER_ADDRESS, "You can't initialize the contract.");
        RECEIVER_CONTRACT = _receiver;
        s_isInitializedLock = true;
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
    function safeMint(address _to, string calldata _nftDescriptionPrompt) public contractIsInitialized {
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

    // TODO: In POC we dont generate the image.
    function _baseURI() internal pure override returns (string memory) {
        return "https://www.youtube.com/watch?v=b89CnP0Iq30";
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

            // Decode prompt from response TODO I'm not sure if this is the right way
            string memory prompt = abi.decode(response, (string));
            s_nftIdToPrompt[tokenId] = prompt;
        }
        delete s_reqIdToUser[requestId];
    }

    // Set by Chainlink CCIP
    // Set nft on chain
    function _ccipReceive(Client.Any2EVMMessage memory _message) internal /*virtual*/ override {
        // decode nftid from message and mark it as onChain
        // s_lastReceivedMessageId = _message.messageId; // fetch the messageId
        require(_message.sourceChainSelector == AVL_FUJI_SELECTOR, "We only accept messages from Fuji.");

        string memory nftId = abi.decode(_message.data, (string)); // abi-decoding of the sent text
        uint256 _nftId = _stringToUint(nftId);
        s_isOnChain[_nftId] = true;
        s_canMove[_nftId] = true;
    }

    /// @notice Construct a CCIP message.
    /// @dev This function will create an EVM2AnyMessage struct with all the necessary information for sending a text.
    /// @param _receiver The address of the receiver.
    /// @param _text The string data to be sent.
    /// @param _feeTokenAddress The address of the token used for fees. Set address(0) for native gas.
    /// @return Client.EVM2AnyMessage Returns an EVM2AnyMessage struct which contains information for sending a CCIP message.
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

    // Made by chatGPT hope it works :d
    function _stringToUint(string memory _s) public pure returns (uint256) {
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

    //**************************** */
    // INHERITANCE TREE AMBIGUITIES
    //**************************** */

    // The following functions are overrides required by Solidity inheritance tree.

    function supportsInterface(bytes4 interfaceId)
        public
        pure // TODO: it was view before check if this is correct
        /*virtual*/
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
