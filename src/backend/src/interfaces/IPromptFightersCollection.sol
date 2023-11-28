// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IPromptFightersCollection
 * @author PromtFighters team: Carlos
 * @dev Interface for interacting with the NFT collection.
 */
interface IPromptFightersCollection {
    // Events
    event PromptFighters__NftMinted(address indexed owner, uint256 nftId);

    // Functions

    /**
     * @dev Before minting the promt, it must pass an AI filter so as to the
     * NFTs are interesting to play with and don't violate any copyright or ethical
     * rules OpenAI has. The filter is applied with Chainlink Functions.
     *
     * @notice Before minting you must approve this contract to use 0.5 LINK to pass the filter.
     * In the future the amounts should be calculated and tested to asses fair prices covering
     * Chainlink Functions and OpenAI's API.
     */
    function safeMint(address to, string calldata nftDescriptionPrompt) external;

    function getPromptOf(uint256 nftId) external returns (string memory);
}
