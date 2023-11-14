// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// Maybe use this funtions to wrap the CCIP implementation and simplify dev-experience
interface ICCIPBridge {
    // Events
    event ICCIPBridge__NftAndFundsSent(
        address indexed user, uint256 indexed chain, uint256 nftID, uint256 funds, uint256 timestamp
    );
    event ICCIPBridge__NftAndFundsReceived(
        address indexed user, uint256 indexed chain, uint256 nftID, uint256 funds, uint256 timestamp
    );

    event ICCIPBridge__NftSent(address indexed user, uint256 indexed chain, uint256 nftID, uint256 timestamp);
    event ICCIPBridge__NftReceived(address indexed user, uint256 indexed chain, uint256 nftID, uint256 timestamp);

    event ICCIPBridge__FundsSent(address indexed user, uint256 indexed chain, uint256 funds, uint256 timestamp);
    event ICCIPBridge__FundsReceived(address indexed user, uint256 indexed chain, uint256 funds, uint256 timestamp);

    // Senders
    function sendNft(uint256 nftId) external;
    function sendFunds(uint256 funds) external;
    function sendNftAndFunds(uint256 nftId, uint256 funds) external;
}
