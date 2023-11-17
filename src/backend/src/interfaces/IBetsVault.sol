// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IFightMatchmaker} from "./IFightMatchmaker.sol";

interface IBetsVault {
    // Data structures

    /**
     * @param timestampEndOfFightLimit is the time where, in the low likelihood that
     * any of chainlink services fail or are not active users will be able to withdraw
     * each its own bet.
     */
    struct BetsState {
        address userOne;
        uint256 betOne;
        address userTwo;
        uint256 betTwo;
        IFightMatchmaker.FightState fightState;
        uint256 timestampAcceptanceDeadline;
        uint256 timestampEndOfFightLimit;
    }

    // Events
    event IBetsVault__FightLocked(address indexed user, uint256 indexed bet, uint256 timestamp);
    event IBetsVault__FightUnocked(address indexed user, uint256 indexed bet, uint256 timestamp);

    // Functions called by requestFight from matchmaker.
    function lockBet(address player) external payable;
    function unlockBet(address player) external payable;

    function checkBetsAreValid(bytes32 fightId, address userOne, uint256 betOne, address userTwo, uint256 betTwo)
        external
        returns (bool);

    // Setters
    function setBetState(uint256 fightId, BetsState calldata state) external;

    // Getters
    function getBet(address user, bytes32 fightId) external returns (uint256);
}
