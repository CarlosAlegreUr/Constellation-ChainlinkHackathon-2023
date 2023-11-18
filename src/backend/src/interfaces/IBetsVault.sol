// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IFightMatchmaker} from "./IFightMatchmaker.sol";

/**
 * @title IBetsVault
 * @author PromptFighters team: Carlos
 * @dev Interface for the BetsVault contract.
 */
interface IBetsVault {
    // Data structures
    struct BetsState {
        address userOne;
        uint256 betOne;
        address userTwo;
        uint256 betTwo;
        bool areBetsLocked;
        uint256 minBet;
        uint256 acceptanceDeadline;
    }

    // Events
    event IBetsVault__BetLocked(address indexed user, uint256 bet, uint256 timestamp);
    event IBetsVault__BetUnocked(address indexed user, uint256 bet, uint256 timestamp);

    // Function called by requestFight() from matchmaker.
    // Function called by acceptFight() from matchmaker.
    // bet is msg.value && bet >= mintBet else revert
    function lockBet(bytes32 fightId, address player) external payable;

    // Called by setFightState() from matchmaker when FightExeutor VRF decides winner
    function distributeBetsPrize(bytes32 _fightId, address _winner) external;

    /**
     * Unlocks your part of the bet in the fightId and
     * sends it back to msg.sender.
     *
     * Only callable if timestamp > acceptanceDeadline && fightState != ONGOING.
     * Or if chainlink services failed.
     *
     * @notice You must be part of fightId.
     */
    function unlockAndRetrieveBet(bytes32 fightId) external;

    // Getters
    function getBetsState(bytes32 fightId) external returns (BetsState memory);
}
