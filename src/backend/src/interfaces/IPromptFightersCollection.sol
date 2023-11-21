// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IPromptFightersCollection
 * @author PromtFighters team: Carlos
 * @dev Interface for interacting with the NFT collection.
 */
interface IPromptFightersCollection {
    event PromptFighters__NftMinted(address indexed owner, uint256 nftId);

    function safeMint(address to, string calldata nftDescriptionPrompt) external;

    function getPrompt(uint256 nftId) external returns (string memory);
}
