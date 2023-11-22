// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ICcipNftBridge} from "../interfaces/ICcipNftBridge.sol";

import {IRouterClient} from "@chainlink-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {OwnerIsCreator} from "@chainlink-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {Client} from "@chainlink-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";

import "../Utils.sol";

contract FightersBarracks is CCIPReceiver, ICcipNftBridge {
    // CCIP nft tracking
    mapping(uint256 => bool) private s_canMove;
    mapping(uint256 => bool) private s_isOnChain;

    // CCIP ownership tracking
    mapping(uint256 => address) private s_nftIdToOwner;

    // Main NFT collection deployed first so here we don't need intializitaion pattern.
    address immutable i_RECIEVER_CONTRACT;

    constructor(address _router, address _receiverContract) CCIPReceiver(_router) {
        i_RECIEVER_CONTRACT = _receiverContract;
    }

    modifier sendNftCrossChainActions(uint64 destinationChainSelector, address receiver, string calldata nftId) {
        uint256 _nftId = _stringToUint(nftId);
        require(getOwnerOf(_nftId) == msg.sender, "You are not the owner.");

        require(destinationChainSelector == ETH_SEPOLIA_SELECTOR, "We only support Sepolia testnet NFT transfers.");
        require(receiver == i_RECIEVER_CONTRACT, "Thats not the receiver contract.");

        require(s_canMove[_nftId], "Nft is bussy can't move.");
        require(s_isOnChain[_nftId], "Nft is not currently in this chain.");

        _;

        s_isOnChain[_nftId] = false;
        s_canMove[_nftId] = false;
    }

    //******************** */
    // EXTERNAL FUNCTIONS
    //******************** */

    // Should have similar logic to the sendMessagePayLINK() of the chainlink docs
    // https://docs.chain.link/ccip/tutorials/send-arbitrary-data
    // In this repo there is an example of transferin NFT cross-chain:
    // https://github.com/smartcontractkit/ccip-starter-kit-foundry
    function sendNft(uint64 _destinationChainSelector, address _receiver, string calldata _nftId)
        external
        payable
        override
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
        emit ICCIPNftBridge__NftSent(msg.sender, ETH_SEPOLIA_SELECTOR, _nftId, block.timestamp);

        // Return the CCIP message ID
        return messageId;
    }

    function isNftOnChain(uint256 nftId) external view returns (bool) {
        return s_isOnChain[nftId];
    }

    //******************** */
    // PUBLIC FUNCTIONS
    //******************** */

    function getOwnerOf(uint256 _nftId) public view returns (address) {
        return s_nftIdToOwner[_nftId];
    }

    //******************** */
    // INTERNAL FUNCTIONS
    //******************** */

    // Set nft on chain
    function _ccipReceive(Client.Any2EVMMessage memory _message) internal /*virtual*/ override {
        // decode nftid from message and mark it as onChain
        // s_lastReceivedMessageId = _message.messageId; // fetch the messageId
        require(_message.sourceChainSelector == ETH_SEPOLIA_SELECTOR, "We only accept messages from Sepolia.");

        string memory nftId = abi.decode(_message.data, (string)); // abi-decoding of the sent text
        uint256 _nftId = _stringToUint(nftId);
        // TODO check if is msg.sender or the contract used to send message¿?
        address _sender = abi.decode(_message.sender, (address)); // abi-decoding of the orginal msg.sender 

        s_isOnChain[_nftId] = true;
        s_canMove[_nftId] = true;
        s_nftIdToOwner[_nftId] = _sender;
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
}
