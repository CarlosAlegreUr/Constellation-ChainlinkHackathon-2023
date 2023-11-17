// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IFightMatchmaker} from "../interfaces/IFightMatchmaker.sol";
import {IFightExecutor} from "../interfaces/IFightExecutor.sol";
import {IBetsVault} from "../interfaces/IBetsVault.sol";

//************************************** */
//            FOR DEVS!
// This contract might need more state
// variables or interface functions.
//
// Feel free to add them if you deem them
// necessary.
//************************************** */

/**
 * @title FightMatchmaker
 * @author PromptFighters team: Carlos
 * @dev This contract handles everything related to matchmaking.
 * Automated matchmaking and normal matchmaking is handled here.
 * @notice This contract assumes that a player can only have 1 fight at a time.
 */
contract FightMatchmaker is IFightMatchmaker {
    //******************** */
    // CONTRACT'S STATE
    //******************** */

    // [ External contracts interacted with ]

    IFightExecutor private immutable i_FIGHT_EXECUTOR_CONTRACT;
    IBetsVault private immutable i_BETS_VAULT;

    // [ Matchmaking related state ]

    mapping(bytes32 => Fight) private s_fightIdToFightState;
    // As a user can only be having 1 fight at a time we only need this mapping
    // to check if the user is busy or not.
    // If ID == 0 then user is not fighting neither looking for one.
    // Make sure address 0 can never appear while creating fights, revert if.
    mapping(address => bytes32) private s_userToFightId;

    // [ Automated matchmaking related state ]

    uint8 constant AUTOAMTED_NFTS_ALLOWED = 5;
    mapping(uint256 => bool) private s_isNftAutomated;
    mapping(uint256 => uint256) private s_atmNftToAtmBet;
    mapping(uint256 => uint256) private s_atmNftToMinBetAcepted;
    // This mapping is treated as an array. For cheaper computation
    // uint8 are indexes and they map to nft's ids. Change it to a normal
    // array if I'm wrong cause I'm not sure.
    mapping(uint8 => uint256) private s_nftsAutomated;
    // Whenver someone request a fight acceptable by anyone then its added to this array.
    FightState[AUTOAMTED_NFTS_ALLOWED] private s_fightsQueue;

    constructor(IFightExecutor _fightExecutorAddress, IBetsVault _betsVaultAddress) {
        i_FIGHT_EXECUTOR_CONTRACT = _fightExecutorAddress;
        i_BETS_VAULT = _betsVaultAddress;
    }

    //******************** */
    // EXTERNAL FUNCTIONS
    //******************** */

    function requestFight(FightRequest calldata fightRequest) external {}

    function acceptFight(bytes32 fightId, uint256 nftId) external {}

    function setFightState(bytes32 fightId, FightState newState) external {}

    //******************** */
    // PUBLIC FUNCTIONS
    //******************** */

    function getFigthId(address _challenger, uint256 _challengerNftId, address _challengee, uint256 _challengeeNftId)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_challenger, _challengerNftId, _challengee, _challengeeNftId));
    }

    function getFightDetails(bytes32 fightId) public returns (Fight memory) {}
    function getUserCurrentFightId(address _user) public returns (bytes32) {}

    function getIsNftAutomated(uint256 nftId) public returns (bool) {}

    function setNftAutomated(uint256 nftId, bool isAutomated) public returns (bool) {}

    //******************** */
    // INTERNAL FUNCTIONS
    //******************** */
    function _setFightState(bytes32 _fightId, FightState _newState) internal {}
}
