// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// This contrat has upkeep functions, one function checks if active fight if not tries to start one
// This might have to be 1 automator contract per player 
interface IFightAutomator {
    // Events
    event IFightAutomator__NftAutoamteStart(uint256 indexed nftId, uint256 startTimestamp);
    event IFightAutomator__NftAutomateStop(
        uint256 indexed nftId, uint256 earnings, uint256 startTimestamp, uint256 endTimestamp
    );

    // Functions
    // Checks in matchmaking if there are any requests and if calls acceptFight
    function searchFight(uint256 bet, uint256 nftId) external;

    // Getters
    function getNftIsAutomated(uint256 nftId) external returns (bool);

    // Setters
    function setNftToAutomatedMode(uint256 nftId, bool isAutomated) external returns (bool);
}
