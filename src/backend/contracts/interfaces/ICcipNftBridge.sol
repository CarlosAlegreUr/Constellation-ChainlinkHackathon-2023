// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ICcipNftBridge
 * @author PromtFighters team: @CarlosAlegreUr
 * @dev Interface for the CcipNftBridge contract.
 */
interface ICcipNftBridge {
    // Events

    event ICCIPNftBridge__NftSent(
        address indexed user, uint256 indexed toChainId, uint256 indexed nftId, bytes32 messageId, uint256 timestamp
    );

    event ICCIPNftBridge__NftReceived(
        address indexed user, uint256 indexed fromChainId, uint256 indexed nftID, uint256 timestamp
    );

    event ICCIPNftBridge__NftIsFightingChanged(uint256 indexed nftId, bool indexed isFighting, uint256 timestamp);

    // Functions

    /**
     * @dev Sends an NFT to the RECEIVER testnet so as to be able to fight on there.
     *
     * This way you leverage costs, example:
     * Sepolia -> safest chain though more expensive
     * Fuji -> cheaper prices.
     *
     * You can only fight with your NFT on the chain it currently is on.
     * For simplicity to use CCIP you have to pay with the native coin -> msg.value
     */
    function sendNft(uint256 nftId) external payable;

    /**
     * @dev Only callable by Matchmaker contract to mark NFTs as fighting or not.
     */
    function setIsNftFighting(uint256 nftId, bool isFightihng) external;

    // Getters

    function getIsNftFighting(uint256 _nftId) external view returns (bool);

    function getIsNftOnChain(uint256 _nftId) external view returns (bool);

    /**
     * @dev Needed to have a generalized way trhough chains of checking for ownership
     * and prompts.
     *
     * As in the main-chain ETH the classic ownerOf() exists but in other chains
     * where the collection is not deployed but just exists a track of ownershp via
     * ccip-transfer from main-chain ownerOf() doesn't exist. Same with prompts, they
     * are saved differently in the main-chain than in other chains.
     *
     * So we need a function to generalize the way we access the ownership state.
     */
    function getOwnerOf(uint256 _nftId) external view returns (address);

    function getPromptOf(uint256 _nftId) external view returns (string memory);

    function getMatchmaker() external view returns (address);

    function getReceiverAddress() external view returns (address);

    function getDetinationChainSelector() external view returns (uint64);

    function getHanldeRecieveFuncSig() external pure returns (string memory);
}
