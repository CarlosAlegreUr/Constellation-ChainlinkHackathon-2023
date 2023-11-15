// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IFightersBarracks {
    // Events
    event FightersBarracks__NftIn(uint256 indexed nftId);
    event FightersBarracks__NftOut(uint256 indexed nftId);

    // Getters
    function isNftOnChain(uint256 nftId) external returns (bool);

    // Setters
    // Set by Chainlink CCIP
    function setNftOnChain(uint256 nftId, bool isOnChain) external returns (bool);
}
