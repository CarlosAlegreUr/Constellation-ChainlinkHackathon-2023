// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IBetsVault} from "./interfaces/IBetsVault.sol";

//************************************** */
//            FOR DEVS!
// This contract might need more state
// variables or interface functions.
//
// Feel free to add them if you deem it
// necessary.
//************************************** */

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
