// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IFightMatchmaker {
    // Events
    event FightMatchmaker__FightRequested(address indexed challenger, uint256 indexed nftId, uint256 indexed bet);
    event FightMatchmaker__FightRequestedTo(
        address indexed challenger, address indexed challenged, uint256 nftIdChallenger, uint256 nftIdChallenged
    );
    event FightMatchmaker__FightAccepted(address indexed challenger, uint256 indexed bet, uint256 nftId);

    // Data Structures
    enum FightState {
        Available,
        Requested,
        InCourse
    }

    // Functions
    // General matchmaking
    function requestFight(uint256 bet, uint256 nftId) external;
    function acceptFight(bytes32 fightId) external;

    // Functiosn for challenging friend trhough ENS
    function requestFightTo(address challenger, uint256 bet, uint256 nftId) external;
    function acceptFightFrom(address challenger, uint256 bet, uint256 nftId) external;

    // Getters
    function getFightState(bytes32 fightId) external returns (FightState);

    // Setters
    function setFightState(bytes32 fightId, FightState newState) external;
}
