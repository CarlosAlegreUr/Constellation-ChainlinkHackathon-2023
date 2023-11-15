// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IFightMatchmaker} from "../interfaces/IFightMatchmaker.sol";
import {IFightExecutor} from "../interfaces/IFightExecutor.sol";

contract FightMatchmaker is IFightMatchmaker {
    //******************** */
    // CONTRACT'S STATE
    //******************** */

    IFightExecutor immutable i_FIGHT_EXECUTOR_CONTRACT;

    mapping(bytes32 => FightState) s_fightIdToFightState;
    // As a user can only be having 1 fight at a time we only need this mapping
    // to check if the user is busy or not.
    mapping(address => bytes32) s_userToFightId;

    constructor(IFightExecutor _fightExecutorAddress) {
        i_FIGHT_EXECUTOR_CONTRACT = _fightExecutorAddress;
    }

    //******************** */
    // EXTERNAL FUNCTIONS
    //******************** */

    //******************** */
    // REQUEST FIGHT FUNCTIONS
    //******************** */

    function requestFight(uint256 nftId) external {}
    function requestFightTo(address challenged, uint256 opponentsNftId, uint256 nftId) external {}
    function requestFightTo(string calldata username, string calldata nftName, uint256 nftId) external {}

    //******************** */
    // START FIGHT FUNCTIONS
    //******************** */
    function acceptFight(bytes32 fightId) external {}
    function acceptFightFrom(address challenger, uint256 nftId) external {}
    function acceptFightFrom(string calldata username, string calldata nftName) external {}
    function declareFightFinished(bytes32 fightId) external {}

    //******************** */
    // SETTERS
    //******************** */

    function setFightState(bytes32 fightId, FightState newState) external {}

    //******************** */
    // GETTERS
    //******************** */
    function getFightState(bytes32 fightId) external returns (FightState) {}
}
