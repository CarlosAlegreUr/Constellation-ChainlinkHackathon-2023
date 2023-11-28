// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ICcipNftBridge} from "./interfaces/ICcipNftBridge.sol";
import {IFightMatchmaker} from "./interfaces/IFightMatchmaker.sol";

import {Initializable} from "./Initializable.sol";

import {IRouterClient} from "@chainlink-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {OwnerIsCreator} from "@chainlink-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {Client} from "@chainlink-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";

import "./Utils.sol";

/**
 * @title CcipNftBridge
 * @author PromtFighters team: Carlos
 * @dev Handles CCIP messaging for this system.
 * Sending and receiving rules are managed here.
 * Rules:
 * - Only 1 chain communication is available.
 * - Messages have a certain coded format from transfering nft data.
 * (format in ICcipMessageCoder.sol)
 */
abstract contract CcipNftBridge is ICcipNftBridge, CCIPReceiver, Initializable {
    // CCIP nft tracking
    // canMove is false if the NFT is fighting
    mapping(uint256 => bool) internal s_isFighting;
    mapping(uint256 => bool) internal s_isOnChain;

    IFightMatchmaker immutable i_FIGHT_MATCHMAKER;

    uint64 immutable i_DESTINATION_CHAIN_SELECTOR;
    // Can't be immutable cause you can't know both addresses before
    // deploying them.
    // (Well maybe you can use CREATE2 for this but lets ignore that I already had the
    // deploy scipts done ;D )
    address i_RECEIVER_ADDRESS;

    //******************** */
    // MODIFIERS
    //******************** */

    /**
     * @dev Only FightMatchmaker contract can call the function for marking NFTs as fighting
     * or not.
     */
    modifier onlyMatchmaker() {
        require(msg.sender == address(i_FIGHT_MATCHMAKER), "Only FightMatchmaker can call this function");
        _;
    }

    //******************** */
    // CONSTRUCTOR
    //******************** */

    constructor(
        uint64 _destinationChainSelector,
        address _receiverAddress,
        address _router,
        IFightMatchmaker _matchmakerContract
    ) CCIPReceiver(_router) {
        i_DESTINATION_CHAIN_SELECTOR = _destinationChainSelector;
        i_RECEIVER_ADDRESS = _receiverAddress;
        i_FIGHT_MATCHMAKER = _matchmakerContract;
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
        i_RECEIVER_ADDRESS = _receiver;
    }

    //******************** */
    // EXTERNAL FUNCTIONS
    //******************** */

    /**
     * @dev Docs at ICcipNftBridge.sol
     */
    function sendNft(address _receiver, string calldata _nftId, string calldata _nftIdStringLength)
        external
        payable
        returns (bytes32 messageId)
    {
        require(_receiver == i_RECEIVER_ADDRESS, "Thats not the receiver contract.");

        uint256 nftIdInt = stringToUint(_nftId);
        _sendNftCrossChainChecksAndUpdates(nftIdInt);

        string memory codedCcipMessage = codeSendNftMessage(_nftId, _nftIdStringLength, getPromptOf(nftIdInt));

        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(_receiver, codedCcipMessage, address(0));

        // Initialize a router client instance to interact with cross-chain router
        IRouterClient router = IRouterClient(this.getRouter());

        // Get the fee required to send the CCIP message
        uint256 fees = router.getFee(i_DESTINATION_CHAIN_SELECTOR, evm2AnyMessage);
        require(fees <= msg.value, "Not enought ETH sent.");

        // Send the CCIP message through the router and store the returned CCIP message ID
        messageId = router.ccipSend{value: fees}(i_DESTINATION_CHAIN_SELECTOR, evm2AnyMessage);

        // Emit an event with message details
        emit ICCIPNftBridge__NftSent(msg.sender, ETH_SEPOLIA_SELECTOR, codedCcipMessage, block.timestamp);

        // Return the CCIP message ID
        return messageId;
    }

    function setIsNftFighting(uint256 nftId, bool isFightihng) external contractIsInitialized onlyMatchmaker {
        s_isFighting[nftId] = isFightihng;
    }

    //******************** */
    // PUBLIC FUNCTIONS
    //******************** */

    function isNftOnChain(uint256 nftId) public view returns (bool) {
        return s_isOnChain[nftId];
    }

    //******************** */
    // INTERNAL FUNCTIONS
    //******************** */

    /**
     * @dev Internal function used in sendNft() to send the message to other chains wit CCIP.
     */
    function _ccipReceive(Client.Any2EVMMessage memory _message) internal /*virtual*/ override {
        // decode nftid from message and mark it as onChain
        // s_lastReceivedMessageId = _message.messageId; // fetch the messageId
        require(_message.sourceChainSelector == ETH_SEPOLIA_SELECTOR, "We only accept messages from Sepolia.");

        string memory codedMessage = abi.decode(_message.data, (string)); // abi-decoding of the sent text
        (string memory nftIdString, string memory prompt) = decodeSendNftMessage(codedMessage);
        uint256 nftIdInt = stringToUint(nftIdString);
        // TODO check if is msg.sender or the contract used to send message¿?
        address sender = abi.decode(_message.sender, (address)); // abi-decoding of the orginal msg.sender

        s_isOnChain[nftIdInt] = true;
        delete s_isFighting[nftIdInt]; // set to false

        _updateNftStateOnReceive(nftIdInt, sender, prompt);

        emit ICCIPNftBridge__NftReceived(getOwnerOf(nftIdInt), AVL_FUJI_CHAIN_ID, nftIdInt, block.timestamp);
    }

    /**
     * @dev Builds the CCIP message struct to send.
     */
    function _buildCCIPMessage(address _receiver, string memory _text, address _feeTokenAddress)
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

    function _sendNftCrossChainChecksAndUpdates(uint256 _nftId) internal {
        // Checks
        require(getOwnerOf(_nftId) == msg.sender, "You are not the owner.");
        require(!s_isFighting[_nftId], "Nft is bussy can't move.");
        require(s_isOnChain[_nftId], "Nft is not currently in this chain.");

        // Updates
        delete s_isOnChain[_nftId];
        delete s_isFighting[_nftId];

        _updateNftStateOnSend(_nftId);
    }

    /**
     * @dev Different chains might track Nfts state differently.
     * Example: collection chain doesnt need to update ownerships or prompts as
     * they are by default always there.
     */
    function _updateNftStateOnSend(uint256 _nftId) internal virtual;

    /**
     * @dev Different chains might track Nfts state differently.
     * Example: collection chain doesnt need to update ownerships or prompts as
     * they are by default always there.
     */
    function _updateNftStateOnReceive(uint256 _nftId, address _owner, string memory _prompt) internal virtual;

    function setOwnerOf(uint256 _nftId, address _owner) internal virtual;

    function setPromptOf(uint256 _nftId, string memory _prompt) internal virtual;

    //************************ */
    // VIEW / PURE FUNCTIONS
    //************************ */

    function getOwnerOf(uint256 _nftId) public view virtual returns (address);

    function getPromptOf(uint256 _nftId) public view virtual returns (string memory);

    //************************ */
    // CCIP MESSAGE ENCODING FUNCS
    //************************ */

    /**
     * @dev Docs in ICcipMessageCoder.sol
     */
    function codeSendNftMessage(
        string calldata _nftIdString,
        string calldata _nftStringLength,
        string memory _nftPrompt
    ) public pure returns (string memory) {
        return string(abi.encodePacked(_nftStringLength, _nftIdString, _nftPrompt));
    }

    /**
     * @dev Docs in ICcipMessageCoder.sol
     */
    function decodeSendNftMessage(string memory _codedSendNftMessage)
        public
        pure
        returns (string memory, string memory)
    {
        bytes memory ccipTextBytes = bytes(_codedSendNftMessage);

        // Convert first character to uint
        uint256 delimiterIndex = stringToUint(string(abi.encodePacked(ccipTextBytes[0])));

        require(delimiterIndex > 0 && delimiterIndex < ccipTextBytes.length, "Invalid delimiter index");

        bytes memory nftId = new bytes(delimiterIndex);
        bytes memory nftPrompt = new bytes(
            ccipTextBytes.length - delimiterIndex - 1
        );

        for (uint256 i = 1; i <= delimiterIndex; i++) {
            nftId[i - 1] = ccipTextBytes[i];
        }

        for (uint256 i = delimiterIndex + 1; i < ccipTextBytes.length; i++) {
            nftPrompt[i - delimiterIndex - 1] = ccipTextBytes[i];
        }

        return (string(nftId), string(nftPrompt));
    }

    // Made by chatGPT hope it works :d
    function stringToUint(string memory _s) public pure returns (uint256) {
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
}
