// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IBetsVault} from "./interfaces/IBetsVault.sol";
import {IFightMatchmaker} from "./interfaces/IFightMatchmaker.sol";
import {ReferencesInitializer} from "./ReferencesInitializer.sol";

/**
 * @title BetsVault
 * @author PromptFighters team: @CarlosAlegreUr
 * @dev This contract handles and stores all the value that is moved
 * around during the systems workflow.
 *
 * When users look for fights they lock their bets here.
 * When users accept any fight they lock their bets here.
 * This contract, when a fight ends, distributes the bets to the winner.
 * In edge-cases where no-one accepts a request or chainlink services fail
 * then this contract also allows for each player to unlock their bets.
 */
contract BetsVault is IBetsVault, ReferencesInitializer {
    //******************************* */
    // CONTRACT'S STATE && CONSTANTS
    //******************************* */

    IFightMatchmaker private i_FIGHT_MATCHMAKER;

    mapping(bytes32 => BetsState) private s_fightIdToBetsState;

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

    /**
     * @dev Docs at IBetsVault.sol
     */
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

    /**
     * @dev Docs at IBetsVault.sol
     */
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
        delete s_fightIdToBetsState[_fightId];
        emit BetsVault__BetsSentToWinner(winner, _fightId, amount, block.timestamp);
    }

    /**
     * @dev Docs at IBetsVault.sol
     */
    function unlockAndRetrieveBet(bytes32 _fightId, address _to)
        external
        contractIsInitialized
        onlyFightMatchmaker
        returns (bool)
    {
        BetsState memory betsState = s_fightIdToBetsState[_fightId];
        require(_to == betsState.requester || _to == betsState.acceptor, "You must be in the fight.");

        // Sending unlocked bet
        bool isRequester = (_to == betsState.requester);
        address receiver = isRequester ? betsState.requester : betsState.acceptor;
        uint256 amount = isRequester ? betsState.requesterBet : betsState.acceptorBet;

        // Updates bets state to see who has already retrieved their bet.
        if (isRequester) {
            delete betsState.requesterBet;
        } else {
            delete betsState.acceptorBet;
        }

        (bool success,) = receiver.call{value: amount}("");
        require(success, "Transfer of unlocked funds failed.");
        delete s_fightIdToBetsState[_fightId];

        // If both players already retrieved their bets the fight becomes AVAILABLE again.
        if (betsState.requesterBet + betsState.acceptorBet == 0) return true;
        else return false;
    }

    //******************** */
    // VIEW / PURE FUNCTIONS
    //******************** */

    function getBetsState(bytes32 _fightId) external view returns (BetsState memory) {
        return s_fightIdToBetsState[_fightId];
    }

    function getMatchmakerAddress() external view returns (address) {
        return address(i_FIGHT_MATCHMAKER);
    }
}
