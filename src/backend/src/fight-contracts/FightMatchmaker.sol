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
// Feel free to add them if you deem it
// necessary.
//************************************** */

/**
 * @title IFightMatchmaker
 * @author PromptFighters team: Carlos
 * @notice This contract assumes that a player can only be having 1 fight at a time.
 * @notice When a fight is made trhough invitation to some specific address it is called a challenge.
 */
contract FightMatchmaker is IFightMatchmaker {
    //******************** */
    // CONTRACT'S STATE
    //******************** */

    // External contracs interacted with
    IFightExecutor private immutable i_FIGHT_EXECUTOR_CONTRACT;
    IBetsVault private immutable i_BETS_VAULT;

    mapping(bytes32 => FightState) private s_fightIdToFightState;
    // As a user can only be having 1 fight at a time we only need this mapping
    // to check if the user is busy or not.
    // If ID == 0 then user is not fighting neither looking for one.
    // Make sure address 0 can never appear while creating fights, revert if.
    mapping(address => bytes32) private s_userToFightId;

    // State for automatic matchmaking
    uint8 constant AUTOMATED_FITHGTS_SIZE = 5;
    mapping(uint8 => uint256) private s_nftsAutomated;
    FightState[AUTOMATED_FITHGTS_SIZE] private s_fightsQueue;

    constructor(IFightExecutor _fightExecutorAddress, IBetsVault _betsVaultAddress) {
        i_FIGHT_EXECUTOR_CONTRACT = _fightExecutorAddress;
        i_BETS_VAULT = _betsVaultAddress;
    }

    //******************** */
    // MODIFIERS
    //******************** */

    /**
     * @dev Checks if msg.sender is `FightExecutor` contract.
     * If not then revert.
     */
    modifier onlyFightExecutorOrBetsVault() {
        require(
            msg.sender == address(i_FIGHT_EXECUTOR_CONTRACT) || msg.sender == address(i_BETS_VAULT),
            "Only FightExecutor or BetsVault can call this."
        );
        _;
    }

    //******************** */
    // EXTERNAL FUNCTIONS
    //******************** */

    //******************** */
    // REQUEST FIGHT FUNCTIONS
    //******************** */

    function requestFight(uint256 _nftId, uint256 _minimumBet, uint256 _acceptanceDeadline) external {}

    function requestFightTo(
        address _challenged,
        uint256 _opponentsNftId,
        uint256 _nftId,
        uint256 _minimumBet,
        uint256 _acceptanceDeadline
    ) external {}

    //******************** */
    // START FIGHT FUNCTIONS
    //******************** */
    function acceptFight(bytes32 _fightId) external {}

    function acceptChallengeFrom(address _challenger, uint256 _nftId) external {}

    function changeFightState(bytes32 _fightId, FightState _newState) external onlyFightExecutorOrBetsVault {}

    //*********************** */
    // AUTOMATED MATCHMAKING
    //*********************** */
    function getNftIsAutomated(uint256 nftId) external returns (bool) {}

    function setNftToAutomatedMode(uint256 nftId, bool isAutomated) external returns (bool) {}

    //******************** */
    // GETTERS
    //******************** */
    function getFightState(bytes32 _fightId) external returns (FightState) {}

    function getUserCurrentFightId(address _user) external returns (bytes32) {}

    function getExecutorContractAddress() public view returns (address) {
        return address(i_FIGHT_EXECUTOR_CONTRACT);
    }

    function getFightId(address _challenger, uint256 _nftId, uint256 _bet) public pure returns (bytes32) {
        return keccak256(abi.encode(_challenger, _nftId, _bet));
    }

    function getChallengeId(
        address _challenger,
        address _challengee,
        uint256 _nftIdChallenger,
        uint256 _nftIdChallengee,
        uint256 _betChallenger,
        uint256 _betChallengee
    ) public pure returns (bytes32) {
        return keccak256(
            abi.encode(_challenger, _challengee, _nftIdChallenger, _nftIdChallengee, _betChallenger, _betChallengee)
        );
    }

    //******************** */
    // INTERNAL FUNCTIONS
    //******************** */

    function _setFightState(bytes32 _fightId, FightState _newState) internal {}
}
