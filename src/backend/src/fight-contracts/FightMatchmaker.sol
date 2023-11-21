// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IFightMatchmaker} from "../interfaces/IFightMatchmaker.sol";
import {IFightExecutor} from "../interfaces/IFightExecutor.sol";
import {IBetsVault} from "../interfaces/IBetsVault.sol";
import {FightExecutor} from "./FightExecutor.sol";

//**************************************** */
//            FOR DEVS!
// This contract might need more state
// variables or functions.
//
// Feel free to add them if you deem them
// necessary while coding. If so, mark them with a comment saying NEW.
//**************************************** */

// TODO: If contract size allows it it will inherit ChainlinkSubsManager and FightExecutor
// and, before calling any service will check for user having funded the subscription.
// In that case a more appropiated name for the contract might be 
// FightsManager is IChainlinkSubsManager, IFightMatchmaker, FightExecutor {}

/**
 * @title FightMatchmaker
 * @author PromptFighters dev team: Carlos
 * @dev Handles matchmaking processes in the game. The matchmaking involves two main steps:
 *
 * 1. requestFight(): Initiates a fight request and emits an event for off-chain detection.
 * 2. acceptFight(): Used to accept a detected fight request and also starts the fight execution.
 *
 * The contract supports automated matchmaking for up to 5 NFTs simultaneously.
 * This limitation is due to the current scope of Chainlink Functions.
 * Future enhancements in Chainlink may allow more NFTs to participate in automated fighting
 * without significantly affecting cost of implementing this mechanic.
 *
 * The current implementation requires storing part of the fight data on-chain for subsequent verifications.
 * Future enhancements are anticipated with Chainlink Functions, especially regarding the import of
 * libraries capable of parsing blockchain logs in the scripts executed by DONs. This advancement
 * will enable encapsulating all necessary fight parameters within event logs. Such a shift will significantly
 * cheapen the fight initiation process, making its automation affordable.
 *
 * @notice Assumes each player is engaged in only one fight at a time.
 */
contract FightMatchmaker is IFightMatchmaker {
    //******************** */
    // CONTRACT'S STATE
    //******************** */

    // [ External contracts interacted with ]

    IFightExecutor private immutable i_FIGHT_EXECUTOR_CONTRACT;
    IBetsVault private immutable i_BETS_VAULT;

    // [ Matchmaking - state ]

    mapping(bytes32 => Fight) private s_fightIdToFightState;
    // As a user can only have 1 fight at a time we only need this mapping
    // to check if the user is fighting or not.
    // If ID == 0 then user is not fighting neither looking for one.
    // @notice Make sure address 0 can never appear while creating fightIds, revert if so.
    mapping(address => bytes32) private s_userToFightId;

    // [ Automated matchmaking - state ]

    uint8 constant AUTOAMTED_NFTS_ALLOWED = 5;
    mapping(uint256 => bool) private s_isNftAutomated;
    // For now, every fight you do in automated mode will have the same amount of bet.
    mapping(uint256 => uint256) private s_atmNftToAtmBet;
    mapping(uint256 => uint256) private s_atmNftToMinBetAcepted;
    // This mapping is treated as an array. For cheaper computation
    // every uint8 is an index and it maps to an nft id.
    // @TODO:Change to a normal array if I'm wrong cause I'm not sure.
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

    function setFightState(bytes32 fightId, FightState newState, uint256 winner) external {}

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
