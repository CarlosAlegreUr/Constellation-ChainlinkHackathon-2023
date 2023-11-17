// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IFightExecutor} from "../interfaces/IFightExecutor.sol";
import {IFightMatchmaker} from "../interfaces/IFightMatchmaker.sol";
import {IFightAutomator} from "../interfaces/IFightAutomator.sol";

//************************************** */
//            FOR DEVS!
// This contract might need more state
// variables or interface functions.
//
// Feel free to add them if you deem it
// necessary.
//************************************** */

//@dev TODO: ADD CHAINLINK FUNCTIONS AND VRF TO THE CONTRACT
contract FightExecutor is IFightExecutor {
    //******************** */
    // CONTRACT'S STATE
    //******************** */

    // External contracs interacted with
    IFightExecutor private immutable i_FIGHT_MATCHMAKER_CONTRACT;
    IFightAutomator private immutable i_FIGHT_AUTOMATOR_CONTRACT;

    bytes private constant s_apiCallFile = "";

    // Block number => fightId => FightReuslt (winner, loser and its nfts)
    // As results are calculated via VRF in a 2 tx process is safe to assume that in each block number
    // there will only be 1 result for each fight ID.
    mapping(uint256 => mapping(bytes32 => FightResult)) private s_fightsResults;

    constructor(IFightExecutor _fightMatchmakerAddress, IFightAutomator _fightAutomatorAddress) {
        i_FIGHT_MATCHMAKER_CONTRACT = _fightMatchmakerAddress;
        i_FIGHT_AUTOMATOR_CONTRACT = _fightAutomatorAddress;
    }

    //******************** */
    // MODIFIERS
    //******************** */

    /**
     * @dev Checks if msg.sender is `FightExecutor` contract.
     * If not then revert.
     */
    modifier onlyFightMatchmakerOrAutomator() {
        require(
            msg.sender == address(i_FIGHT_MATCHMAKER_CONTRACT) || msg.sender == address(i_FIGHT_AUTOMATOR_CONTRACT),
            "Only FightExecutor can call this."
        );
        _;
    }

    //******************** */
    // EXTERNAL FUNCTIONS
    //******************** */

    function startFight(address[2] calldata _participants, uint256[2] calldata _nftIds)
        external
        onlyFightMatchmakerOrAutomator
    {
        // Call Chainlink Functions
        // On the return function, not this one, call VRF
    }

    //******************** */
    // GETTERS
    //******************** */

    function getFunctionsFile() public pure returns (bytes memory) {
        return s_apiCallFile;
    }
}
