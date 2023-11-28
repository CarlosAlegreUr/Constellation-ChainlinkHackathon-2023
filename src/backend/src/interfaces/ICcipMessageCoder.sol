// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title ICcipMessageCoder
 * @author PromtFighters team: Carlos
 * @dev Handle message formatting for CCIP.
 *
 * Format:
 *
 * "offset" + "nftId" + "nftPrompt"
 *
 * - Offset is the index where nftPrompt starts.
 * - nftId is the nft Id.
 * - nftPromtp is the prompt of the nftId
 */
interface ICcipMessageCoder {
    // Functions

    /**
     * @dev Returns the encoded value you have to send to
     * sendNft() to send the NFT cross-chain.
     */
    function codeSendNftMessage(
        string calldata _nftIdString,
        string calldata _nftStringLength,
        string memory _nftPrompt
    ) external pure returns (string memory);

    /**
     * @dev Decodes message sending NFT crosschains.
     * @return Returns first the nftId and second the prompt.
     */
    function decodeSendNftMessage(string memory _codedSendNftMessage)
        external
        pure
        returns (string memory, string memory);

    // Made by chatGPT hope it works :d
    function stringToUint(string memory _s) external pure returns (uint256);
}
