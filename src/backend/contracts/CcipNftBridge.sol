// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ICcipNftBridge} from "./interfaces/ICcipNftBridge.sol";
import {IFightMatchmaker} from "./interfaces/IFightMatchmaker.sol";

import {ReferencesInitializer} from "./ReferencesInitializer.sol";

import {IRouterClient} from "@chainlink-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {OwnerIsCreator} from "@chainlink-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {Client} from "@chainlink-ccip/src/v0.8/ccip/libraries/Client.sol";
// import {CCIPReceiver} from "@chainlink-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";
// Using personalized version for compatibility with Chainlink Functions
import {CCIPReceiver} from "./libEdits/edit-CCIPReceiver.sol";

import "./Utils.sol";

import "forge-std/console.sol";

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
abstract contract CcipNftBridge is ICcipNftBridge, CCIPReceiver, ReferencesInitializer {
    // CCIP nft tracking
    // canMove is false if the NFT is fighting
    mapping(uint256 => bool) internal s_isFighting;
    mapping(uint256 => bool) internal s_isOnChain;

    // IFightMatchmaker immutable i_FIGHT_MATCHMAKER;

    // TODO: delete after testing
    IFightMatchmaker i_FIGHT_MATCHMAKER;

    // TODO: delete after testing
    function setMatchmaker(address m) external {
        require(DEPLOYER == msg.sender);
        i_FIGHT_MATCHMAKER = IFightMatchmaker(m);
    }

    // TODO: delete after testing
    function nftFighting(uint256 m, bool fight) external {
        require(DEPLOYER == msg.sender);
        s_isFighting[m] = fight;
    }

    string constant HANDLE_RECEIVE_NFT_FUNCTION_SIG = "_updateNftStateOnReceive(uint256,address,string)";

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

    function initializeReferences(address[] calldata _references) external override initializeActions {
        i_RECEIVER_ADDRESS = _references[0];
    }

    //******************** */
    // EXTERNAL FUNCTIONS
    //******************** */

    /**
     * @dev Docs at ICcipNftBridge.sol
     */
    function sendNft(uint256 _nftId) external payable contractIsInitialized returns (bytes32 messageId) {
        bytes memory codedCcipMessage =
            abi.encodeWithSignature(HANDLE_RECEIVE_NFT_FUNCTION_SIG, _nftId, msg.sender, getPromptOf(_nftId));

        // Also checks for ownership etc...
        _updateNftStateOnSend(_nftId);

        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        Client.EVM2AnyMessage memory evm2AnyMessage =
            _buildCCIPMessage(i_RECEIVER_ADDRESS, codedCcipMessage, address(0));

        // Initialize a router client instance to interact with cross-chain router
        IRouterClient router = IRouterClient(this.getRouter());

        // Get the fee required to send the CCIP message
        uint256 fees = router.getFee(i_DESTINATION_CHAIN_SELECTOR, evm2AnyMessage);
        require(fees <= msg.value, "Not enought ETH sent.");

        // Send the CCIP message through the router and store the returned CCIP message ID
        messageId = router.ccipSend{value: fees}(i_DESTINATION_CHAIN_SELECTOR, evm2AnyMessage);

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
        require(_message.sourceChainSelector == i_DESTINATION_CHAIN_SELECTOR, "We only accept messages from 1 chain.");
        address sender = abi.decode(_message.sender, (address)); // abi-decoding of the orginal msg.sender

        require(sender == i_RECEIVER_ADDRESS, "Only accept messages from collection contract.");

        // data corresponds to calling => _updateNftStateOnReceive()
        (bool success,) = address(this).call(_message.data);
        require(success, "Something failed updating NFT state.");
    }

    /**
     * @dev Builds the CCIP message struct to send.
     */
    function _buildCCIPMessage(address _receiver, bytes memory _encodedMessage, address _feeTokenAddress)
        internal
        pure
        returns (Client.EVM2AnyMessage memory)
    {
        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        return Client.EVM2AnyMessage({
            receiver: abi.encode(_receiver), // ABI-encoded receiver address
            data: _encodedMessage, // ABI-encoded string
            tokenAmounts: new Client.EVMTokenAmount[](0), // Empty array aas no tokens are transferred
            extraArgs: Client._argsToBytes(
                // Additional arguments, setting gas limit and non-strict sequencing mode
                Client.EVMExtraArgsV1({gasLimit: 200_000, strict: false})
                ),
            // Set the feeToken to a feeTokenAddress, indicating specific asset will be used for fees
            feeToken: _feeTokenAddress
        });
    }

    function _updateNftStateOnSend(uint256 _nftId) internal {
        // Checks
        require(getOwnerOf(_nftId) == msg.sender, "You are not the owner.");
        require(!s_isFighting[_nftId], "Nft is bussy can't move.");
        require(s_isOnChain[_nftId], "Nft is not currently in this chain.");

        // Updates
        delete s_isOnChain[_nftId];
        delete s_isFighting[_nftId];

        _updateNftStateOnSendChainSpecifics(_nftId);
    }

    function _updateNftStateOnReceive(uint256 _nftId, address _owner, string memory _prompt) external {
        require(msg.sender == address(this));

        s_isOnChain[_nftId] = true;
        delete s_isFighting[_nftId]; // set to false
        _updateNftStateOnReceiveChainSpecifics(_nftId, _owner, _prompt);
    }

    /**
     * @dev Different chains might track Nfts state differently.
     * Example: collection chain doesnt need to update ownerships or prompts as
     * they are by default always there.
     */
    function _updateNftStateOnSendChainSpecifics(uint256 _nftId) internal virtual;

    /**
     * @dev Different chains might track Nfts state differently.
     * Example: collection chain doesnt need to update ownerships or prompts as
     * they are by default always there.
     */
    function _updateNftStateOnReceiveChainSpecifics(uint256 _nftId, address _owner, string memory _prompt)
        internal
        virtual;

    // Internal Setters

    function setOwnerOf(uint256 _nftId, address _owner) internal virtual;

    function setPromptOf(uint256 _nftId, string memory _prompt) internal virtual;

    //************************ */
    // VIEW / PURE FUNCTIONS
    //************************ */

    function getOwnerOf(uint256 _nftId) public view virtual returns (address);

    function getPromptOf(uint256 _nftId) public view virtual returns (string memory);

    function getIsNftFighting(uint256 _nftId) public view returns (bool) {
        return s_isFighting[_nftId];
    }

    function getIsNftOnChain(uint256 _nftId) public view returns (bool) {
        return s_isOnChain[_nftId];
    }

    // @notice Overriden so in the contracts with inheriting conflict they can still
    // access CCIPReceiver its IERC165.
    function supportsInterface(bytes4 interfaceId)
        public
        view
        /**
         * @notice Changed to view for funcs compatibility
         */
        virtual
        override
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
