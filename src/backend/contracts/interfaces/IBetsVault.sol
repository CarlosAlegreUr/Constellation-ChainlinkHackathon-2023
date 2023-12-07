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

    /**
     * @param areBetsLocked bool indicating if both bets are locked
     * @param minBet minimum bet tolerated by requester
     * @param acceptanceDeadline date/time when a non-accepted request's bet can be unlocked
     */
    struct BetsState {
        address requester;
        uint256 requesterBet;
        address acceptor;
        uint256 acceptorBet;
        bool areBetsLocked;
    }

    // Events
    event BetsVault__BetLocked(address indexed user, bytes32 indexed fightId, uint256 bet, uint256 timestamp);
    event BetsVault__BetUnocked(address indexed user, bytes32 indexed fightId, uint256 bet, uint256 timestamp);
    event BetsVault__BetsSentToWinner(
        address indexed winner, bytes32 indexed fightId, uint256 totalBets, uint256 timestamp
    );

    // Functions

    /**
     * @dev This functions locks the bets of fighters before a fight starts.
     * Function called by requestFight() || acceptFight() from matchmaker.
     *
     * @notice This func expects all input and state sanity checks have been done
     * in `FightMatchmaker` contract.
     *
     * @param fightId id of fight
     * @param player player requesting or accepting a fight
     */
    function lockBet(bytes32 fightId, address player) external payable;

    /**
     * @dev Checks if `_winner` is requester or acceptor and sends the sum
     * of the bets in the fight to the winner.
     *
     * Called by setFightState() from matchmaker after `FightExeutor` VRF notifies
     * the winner bit to matchmaker.
     *
     * @notice This func expects all input and state
     * sanity checks have been done in `FightMatchmaker` contract.
     */
    function distributeBetsPrize(bytes32 _fightId, address _winner) external payable;

    /**
     * @dev Callable by Matchmaker when:
     *
     * 1.- No-one accepted fight in time.
     * 2.- Chainlink services failed for too long.
     *
     * @return Indicates to Matchmaker if it should delete the fight data or not.
     * It only should if both players already retrieved the bet from a fight.
     */
    function unlockAndRetrieveBet(bytes32 fightId, address to) external returns (bool);

    // Getters

    function getBetsState(bytes32 fightId) external view returns (BetsState memory);

    function getMatchmakerAddress() external view returns (address);
}
