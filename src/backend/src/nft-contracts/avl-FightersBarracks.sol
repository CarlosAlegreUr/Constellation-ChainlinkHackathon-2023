// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ICcipNftBridge} from "../interfaces/ICcipNftBridge.sol";
import {IFightMatchmaker} from "../interfaces/IFightMatchmaker.sol";

import {IRouterClient} from "@chainlink-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {OwnerIsCreator} from "@chainlink-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {Client} from "@chainlink-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";

import "../Utils.sol";

/**
 * @title FightersBarracks
 * @author PromtFighters team: Carlos
 * @dev Tracks ownership and NFTs states for NFTs on chains
 * that are not the Ethereum one. For now only usable in Fuji testnet.
 */
contract FightersBarracks is CCIPReceiver, ICcipNftBridge {
    // CCIP nft tracking
    // canMove is false if the NFT is fighting -> changed for s_nftIsFighting
    mapping(uint256 => bool) private s_nftIsFighting;
    mapping(uint256 => bool) private s_isOnChain;

    // CCIP ownership tracking
    mapping(uint256 => address) private s_nftIdToOwner;

    // Main NFT collection deployed first so here we don't need intializitaion pattern.
    address immutable i_RECIEVER_CONTRACT;
    IFightMatchmaker immutable i_FIGHT_MATCHMAKER;

    // Fight state tracking

    constructor(address _router, address _receiverContract, IFightMatchmaker _fightMatchmaker) CCIPReceiver(_router) {
        require(_router == AVL_FUJI_CCIP_ROUTER, "Not allowed router.");
        i_RECIEVER_CONTRACT = _receiverContract;
        i_FIGHT_MATCHMAKER = _fightMatchmaker;
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
        uint256 nftIdInt = _stringToUint(nftId);
        require(getOwnerOf(nftIdInt) == msg.sender, "You are not the owner.");

        require(destinationChainSelector == ETH_SEPOLIA_SELECTOR, "We only support Sepolia testnet NFT transfers.");
        require(receiver == i_RECIEVER_CONTRACT, "Thats not the receiver contract.");

        require(!s_nftIsFighting[nftIdInt], "Nft is bussy can't move.");
        require(s_isOnChain[nftIdInt], "Nft is not currently in this chain.");

        _;

        delete s_isOnChain[nftIdInt];
        delete s_nftIsFighting[nftIdInt];
        // Maybe this delete is not needed, kept just in case.
        delete s_nftIdToOwner[nftIdInt];
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
    function sendNft(uint64 _destinationChainSelector, address _receiver, string calldata nftIdInt)
        external
        payable
        override
        sendNftCrossChainActions(_destinationChainSelector, _receiver, nftIdInt)
        returns (bytes32 messageId)
    {
        // Create an EVM2AnyMessage struct in memory with necessary information for sending a cross-chain message
        Client.EVM2AnyMessage memory evm2AnyMessage = _buildCCIPMessage(_receiver, nftIdInt, address(0));

        // Initialize a router client instance to interact with cross-chain router
        IRouterClient router = IRouterClient(this.getRouter());

        // Get the fee required to send the CCIP message
        uint256 fees = router.getFee(_destinationChainSelector, evm2AnyMessage);
        require(fees <= msg.value, "Not enought ETH sent.");

        // Send the CCIP message through the router and store the returned CCIP message ID
        messageId = router.ccipSend{value: fees}(_destinationChainSelector, evm2AnyMessage);

        // Emit an event with message details
        emit ICCIPNftBridge__NftSent(msg.sender, ETH_SEPOLIA_SELECTOR, nftIdInt, block.timestamp);

        // Return the CCIP message ID
        return messageId;
    }

    function isNftOnChain(uint256 nftId) external view returns (bool) {
        return s_isOnChain[nftId];
    }

    function setNftIsFighting(uint256 nftId, bool isFighting) external onlyMatchmaker {
        s_nftIsFighting[nftId] = isFighting;
    }

    //******************** */
    // PUBLIC FUNCTIONS
    //******************** */

    function getOwnerOf(uint256 nftIdInt) public view returns (address) {
        return s_nftIdToOwner[nftIdInt];
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

        string memory nftId = abi.decode(_message.data, (string)); // abi-decoding of the sent text
        uint256 nftIdInt = _stringToUint(nftId);
        // TODO check if is msg.sender or the contract used to send message¿?
        address sender = abi.decode(_message.sender, (address)); // abi-decoding of the orginal msg.sender

        s_isOnChain[nftIdInt] = true;
        s_nftIsFighting[nftIdInt] = false;
        s_nftIdToOwner[nftIdInt] = sender;
        emit ICCIPNftBridge__NftReceived(getOwnerOf(nftIdInt), AVL_FUJI_CHAIN_ID, nftIdInt, block.timestamp);
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
}
