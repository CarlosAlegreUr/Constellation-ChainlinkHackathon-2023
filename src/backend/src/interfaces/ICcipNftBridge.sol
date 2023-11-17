// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Maybe use this funtions to wrap the CCIP implementation and simplify dev-experience
// This will serve as a lock and mint vault for the ethereum coin. If a user wants to
// use funds (only ethereum coin for this project) then they will call the bridge, lock the
// coin in a bridge contract and mint a collateral asset on the destination chain.
interface ICcipNftBridge {
    // Events
    event ICCIPNftBridge__NftSent(
        address indexed user, uint256 indexed chain, uint256 indexed nftID, uint256 timestamp
    );
    event ICCIPNftBridge__NftReceived(
        address indexed user, uint256 indexed chain, uint256 indexed nftID, uint256 timestamp
    );

    // Senders
    function sendNft(uint256 nftId) external;

    // Getters
    function isNftOnChain(uint256 nftId) external returns (bool);
}
