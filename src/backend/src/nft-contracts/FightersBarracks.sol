// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ICcipNftBridge} from "../interfaces/ICcipNftBridge.sol";

contract FightersBarracks is ICcipNftBridge {
    function sendNft(uint256 nftId) external {}

    // Getters
    function isNftOnChain(uint256 nftId) external returns (bool) {}

    // Setters
    // Set by Chainlink CCIP
    function setNftOnChain(uint256 nftId, bool isOnChain) external returns (bool) {}
}
