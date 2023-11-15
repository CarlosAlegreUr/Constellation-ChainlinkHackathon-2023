// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IBetsVault {
    // Data structures
    struct BetsState {
        address userOne;
        uint256 betOne;
        address userTwo;
        uint256 betTwo;
    }

    // Events
    event IBetsVault__FightLocked(address indexed user, uint256 indexed bet, uint256 timestamp);
    event IBetsVault__FightUnocked(address indexed user, uint256 indexed bet, uint256 timestamp);

    // Functions called by requestFight from matchmaker.
    function lockBet(address player) external;
    function unlockBet(address player) external;

    // Setters
    function setBetState(uint256 fightId, BetsState calldata state) external;

    // Getters
    function getBet(address user) external returns (uint256);
}
