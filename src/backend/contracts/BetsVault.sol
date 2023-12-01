// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IBetsVault} from "./interfaces/IBetsVault.sol";
import {IFightMatchmaker} from "./interfaces/IFightMatchmaker.sol";
import {ReferencesInitializer} from "./ReferencesInitializer.sol";
import {NOT_DECIDING_WINNER_VALUE} from "./Utils.sol";

/**
 * @title BetsVault
 * @author PromptFighters team: Carlos
 * @dev This contract handles and stores all the value that is moved
 * around during the systems workflow.
 *
 * When users look for fights they lock their bets here.
 * When users accept any fight they lock their bets here.
 * This contract, when a fight ends, distributes the bets to the winner.
 * In edge-cases where no-one accepts a request or chainlink services fail
 * then this contract also allows for each player to unlock their bets.
 *
 * @notice This contract assumes all inputs and states recieved and checked
 * are correctly handled by the `FightMatchmaker` contract.
 */
contract BetsVault is IBetsVault, ReferencesInitializer {
    //******************************* */
    // CONTRACT'S STATE && CONSTANTS
    //******************************* */

    // In case Chainlink Services fail and users funds are locked,
    // after 1 day they will be able to retrieve them from the contract.
    uint256 constant APOCALIPSIS_SAFETY_NET = 1 days;

    // Contracts interacted with
    IFightMatchmaker private i_FIGHT_MATCHMAKER;

    mapping(bytes32 => BetsState) s_fightIdToBetsState;

    function initializeReferences(address[] calldata _references) external override initializeActions {
        i_FIGHT_MATCHMAKER = IFightMatchmaker(_references[0]);
    }

    //******************** */
    // MODIFIERS
    //******************** */

    modifier onlyFightMatchmaker() {
        require(msg.sender == address(i_FIGHT_MATCHMAKER), "Only FightMatchmacker is allowed.");
        _;
    }

    //******************** */
    // EXTERNAL FUNCTIONS
    //******************** */

    // TODO: to check reentrancy risks when executor and matchmaker are coded
    function lockBet(bytes32 _fightId, address _player) external payable contractIsInitialized onlyFightMatchmaker {
        BetsState memory currentBetsState = s_fightIdToBetsState[_fightId];

        // If requester is not set it is because it being called from requestFight().
        bool callingFromRequest = (currentBetsState.requester == address(0));
        if (callingFromRequest) {
            currentBetsState.requester = _player;
            currentBetsState.requesterBet = msg.value;
            currentBetsState.areBetsLocked = true;
        } else {
            // Calling from acceptRequest()
            currentBetsState.acceptor = _player;
            currentBetsState.acceptorBet = msg.value;
        }

        s_fightIdToBetsState[_fightId] = currentBetsState;
        emit BetsVault__BetLocked(_player, _fightId, msg.value, block.timestamp);
    }

    // TODO: to check reentrancy risks when executor and matchmaker are coded
    function distributeBetsPrize(bytes32 _fightId, address _winner)
        external
        payable
        contractIsInitialized
        onlyFightMatchmaker
    {
        BetsState memory betsState = s_fightIdToBetsState[_fightId];
        address winner = (_winner == betsState.requester) ? betsState.requester : betsState.acceptor;
        uint256 amount = betsState.acceptorBet + betsState.requesterBet;
        (bool success,) = winner.call{value: amount}("");
        require(success, "Transfer prize to winner failed.");
        emit BetsVault__BetsSentToWinner(winner, _fightId, amount, block.timestamp);
    }

    function unlockAndRetrieveBet(bytes32 _fightId) external contractIsInitialized {
        BetsState memory betsState = s_fightIdToBetsState[_fightId];
        require(msg.sender == betsState.requester || msg.sender == betsState.acceptor, "You must be in the fight.");
        IFightMatchmaker.Fight memory fightDetails = i_FIGHT_MATCHMAKER.getFightDetails(_fightId);

        // If can't unlock it will revert
        _checkUnlockConditions(fightDetails);

        // Sending unlocked bet
        bool isRequester = (msg.sender == betsState.requester);
        address receiver = isRequester ? betsState.requester : betsState.acceptor;
        uint256 amount = isRequester ? betsState.requesterBet : betsState.acceptorBet;

        // Updates bets state to see who has already retrieved their bet.
        if (isRequester) {
            delete betsState.requesterBet;
        } else {
            delete betsState.acceptorBet;
        }

        // If both players already retrieved their bets the fight becomes AVAILABLE again.
        if (betsState.requesterBet + betsState.acceptorBet == 0) {
            i_FIGHT_MATCHMAKER.setFightState(_fightId, IFightMatchmaker.FightState.AVAILABLE, NOT_DECIDING_WINNER_VALUE);
            delete s_fightIdToBetsState[_fightId];
        }

        (bool success,) = receiver.call{value: amount}("");
        require(success, "Transfer of unlocked funds failed.");
    }

    //******************** */
    // PRIVATE FUNCTIONS
    //******************** */

    /**
     * @dev You can unlock if:
     *
     * Fight is REQUESTED && current time > acceptance deadline
     * Fight is ONGOING && current time > start time + APOCALIPSIS_SAFETY_NET
     */
    function _checkUnlockConditions(IFightMatchmaker.Fight memory _fightDetails) private view {
        bool canUnlock;

        // Check for no-one accepted on time.
        if (
            _fightDetails.state == IFightMatchmaker.FightState.REQUESTED
                && _fightDetails.acceptanceDeadline < block.timestamp
        ) {
            canUnlock = true;
        }

        // Check for Chainlink services failing.
        if (
            _fightDetails.state == IFightMatchmaker.FightState.ONGOING
                && _fightDetails.startedAt + APOCALIPSIS_SAFETY_NET < block.timestamp
        ) {
            canUnlock = true;
        }

        require(canUnlock, "Can't unlock yet.");
    }

    //******************** */
    // VIEW / PURE FUNCTIONS
    //******************** */

    function getBetsState(bytes32 _fightId) external view returns (BetsState memory) {
        return s_fightIdToBetsState[_fightId];
    }

    function getApocalispsisSafetyNet() external pure returns (uint256) {
        return APOCALIPSIS_SAFETY_NET;
    }
}
