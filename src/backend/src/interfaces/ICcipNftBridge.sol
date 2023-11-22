// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Maybe use this funtions to wrap the CCIP implementation and simplify dev-experience
// This will serve as a lock and mint vault for the ethereum coin. If a user wants to
// use funds (only ethereum coin for this project) then they will call the bridge, lock the
// coin in a bridge contract and mint a collateral asset on the destination chain.
interface ICcipNftBridge {
    // Events
    event ICCIPNftBridge__NftSent(
        address indexed user, uint64 indexed chainSelector, string indexed nftId, uint256 timestamp
    );
    event ICCIPNftBridge__NftReceived(
        address indexed user, uint256 indexed chain, uint256 indexed nftID, uint256 timestamp
    );

    // Senders
    function sendNft(uint64 _destinationChainSelector, address _receiver, string calldata _text)
        external
        payable
        returns (bytes32 messageId);

    // Getters
    function isNftOnChain(uint256 nftId) external view returns (bool);

    /**
     * @dev Needed to have a generalized way trhough chains of checking for ownership.
     * As in the main-chain ETH the classic ownerOf() exists but in other chains
     * where the collection is not deployed but it just exists a track of ownershp via
     * ccip-transfer from main-chain.
     *
     * Therefore ownerOf() doesn't exist as those contracts are not ERC721 but just
     * ownership mappings assigned at transfered time. So we need a function to generalize
     * the code so we don't have to create slighly different new Matchmaker contracts for
     * each chain.
     *
     * TODO: revise Matchmaker an associeted contracts to use getOwnerOf()
     */
    function getOwnerOf(uint256 _nftId) external view returns (address);
}
