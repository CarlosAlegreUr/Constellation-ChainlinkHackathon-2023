// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Maybe use this funtions to wrap the CCIP implementation and simplify dev-experience
// This will serve as a lock and mint vault for the ethereum coin. If a user wants to 
// use funds (only ethereum coin for this project) then they will call the bridge, lock the
// coin in a bridge contract and mint a collateral asset on the destination chain. 
interface ICCIPAssetsBridge {
    // Events
    event ICCIPAssetsBridge__NftAndFundsSent(
        address indexed user, uint256 indexed chain, uint256 nftID, uint256 funds, uint256 timestamp
    );
    event ICCIPAssetsBridge__NftAndFundsReceived(
        address indexed user, uint256 indexed chain, uint256 nftID, uint256 funds, uint256 timestamp
    );

    event ICCIPAssetsBridge__NftSent(address indexed user, uint256 indexed chain, uint256 nftID, uint256 timestamp);
    event ICCIPAssetsBridge__NftReceived(address indexed user, uint256 indexed chain, uint256 nftID, uint256 timestamp);

    event ICCIPAssetsBridge__FundsSent(address indexed user, uint256 indexed chain, uint256 funds, uint256 timestamp);
    event ICCIPAssetsBridge__FundsReceived(address indexed user, uint256 indexed chain, uint256 funds, uint256 timestamp);

    // Senders
    function sendNft(uint256 nftId) external;
    function sendFunds(uint256 funds) external;
    function sendNftAndFunds(uint256 nftId, uint256 funds) external;
}
