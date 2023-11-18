// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IBetsVault} from "./interfaces/IBetsVault.sol";

//**************************************** */
//            FOR DEVS!
// This contract might need more state
// variables or functions.
//
// Feel free to add them if you deem them
// necessary while coding. If so, mark them with a comment saying NEW.
//**************************************** */

/**
 * @title BetsVault
 * @author PromptFighters team: Carlos
 * @dev This contract handles and stores all the value that is moved
 * around during the systems workflow.
 * 
 * When users look for fights they lock their bets here.
 * When users accept any fight they lock their bets here.
 * This contract, whena fight ends, distributes the bets to the winner.
 * In edge-cases where no-one accepts a request or chainlink services fail
 * then this contract also allows for each player to unlock their bets. 
 */
contract BetsVault is IBetsVault {
    // In case Chainlink Services fail and users funds are locked
    // after 1 day they will be able to retrieve them from the contract.
    uint256 constant APOCALIPSIS_SAFETY_NET = 1 days;

    mapping(bytes32 => BetsState) s_fightIdToBetsState;

    // Functions ONLY called by requestFight from matchmaker.
    function lockBet(bytes32 fightId, address player) external payable {}

    // Only callable by FightMatchmaker contract
    function distributeBetsPrize(bytes32 _fightId, address _winner) external {}

    function unlockAndRetrieveBet(bytes32 fightId) external {}

    function getBetsState(bytes32 fightId) external returns (BetsState memory) {}
}
