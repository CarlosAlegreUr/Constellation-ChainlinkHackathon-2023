// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IFightMatchmaker} from "../interfaces/IFightMatchmaker.sol";
import {IFightExecutor} from "../interfaces/IFightExecutor.sol";
import {IBetsVault} from "../interfaces/IBetsVault.sol";
import {PromptFightersNFT} from "../nft-contracts/eth-PromptFightersNft.sol";
import {ChainlinkFuncsGist} from "../Utils.sol";

//**************************************** */
//            FOR DEVS!
// This contract might need more state
// variables or functions.
//
// Feel free to add them if you deem them
// necessary while coding. If so, mark them with a comment saying NEW.
//**************************************** */

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
    PromptFightersNFT private immutable i_PROMPT_FIGHTERS_NFT;

    // [ Matchmaking - state ]

    mapping(bytes32 => Fight) private s_fightIdToFight;
    // As a user can only have 1 fight at a time we only need this mapping
    // to check if the user is fighting or not.
    // If ID == 0 then user is not fighting neither looking for one.
    // @notice Make sure address 0 can never appear while creating fightIds, revert if so.
    mapping(address => bytes32) private s_userToFightId;

    // [ Automated matchmaking - state ]

    uint8 constant AUTOMATED_NFTS_ALLOWED = 5;
    mapping(uint256 => bool) private s_isNftAutomated;
    // For now, every fight you do in automated mode will have the same amount of bet.
    mapping(uint256 => uint256) private s_atmNftToAtmBet;
    mapping(uint256 => uint256) private s_atmNftToMinBetAcepted;
    // This mapping is treated as an array. For cheaper computation
    // every uint8 is an index and it maps to an nft id.
    // @TODO:Change to a normal array if I'm wrong cause I'm not sure.
    mapping(uint8 => uint256) private s_nftsAutomated;
    // Whenever someone requests a fight acceptable by anyone then it's added to this array.
    bytes32[AUTOMATED_NFTS_ALLOWED] private s_fightIdsQueue;
    uint8 s_nextIndexFightQueue;

    //******************** */
    // MODIFIERS
    //******************** */

    /**
     * @dev Checks if msg.sender is `FightExecutor` contract or `BetsVault` contract.
     * If not then revert.
     */
    modifier onlyFightExecutorOrBetsVault() {
        require(
            msg.sender == address(i_FIGHT_EXECUTOR_CONTRACT) || msg.sender == address(i_BETS_VAULT),
            "Only FightExecutor or BetsVault can call this."
        );
        _;
    }

    constructor(
        IFightExecutor _fightExecutorAddress,
        IBetsVault _betsVaultAddress,
        PromptFightersNFT _promptFightersNftAddress
    ) {
        i_FIGHT_EXECUTOR_CONTRACT = _fightExecutorAddress;
        i_BETS_VAULT = _betsVaultAddress;
        i_PROMPT_FIGHTERS_NFT = _promptFightersNftAddress;
    }

    //*********************/
    // EXTERNAL FUNCTIONS
    //*********************/

    function requestFight(FightRequest calldata _fightRequest) external payable {
        address[2] memory participants = [msg.sender, _fightRequest.challengeeAddress];
        uint256[2] memory nftIds = [_fightRequest.challengerNftId, _fightRequest.challengeeNftId];

        for (uint8 i = 0; i < nftIds.length; i++) {
            if (!i_PROMPT_FIGHTERS_NFT.isNftOnChain(nftIds[i])) {
                revert FightMatchMaker__NftNotOnThisChain(nftIds[i], block.chainid);
            }
        }

        if (msg.sender != i_PROMPT_FIGHTERS_NFT.getOwnerOf(nftIds[0])) {
            revert FightMatchMaker__NftNotOwnedByChallenger(msg.sender, nftIds[0]);
        }

        if (nftIds[1] != 0 && participants[1] != i_PROMPT_FIGHTERS_NFT.getOwnerOf(nftIds[1])) {
            revert FightMatchMaker__NftNotOwnedByChallengee(participants[1], nftIds[1]);
        }

        bytes32 fightId = getFightId(participants[0], nftIds[0], participants[1], nftIds[1]);

        if (getUserCurrentFight(msg.sender).state != FightState.AVAILABLE) {
            revert FightMatchMaker__FightNotAvailable(msg.sender, fightId);
        }

        Fight memory fight = Fight(
            // participants[0],
            // participants[1],
            nftIds[0],
            nftIds[1],
            _fightRequest.minBet,
            _fightRequest.acceptanceDeadline,
            block.timestamp,
            FightState.REQUESTED
        );

        try i_BETS_VAULT.lockBet{value: msg.value}(fightId, msg.sender) {
            // if (getUserCurrentFightId(msg.sender) == fightId) {
            //     //If fight requested existed already, update state
            //     _updateFightState(fightId, FightState.REQUESTED);
            // } else {
            _setUserFightId(msg.sender, fightId); // setting msg.sender -> fightId means requester has made a request
            _setFight(fightId, fight);
            // }

            if (participants[1] == address(0)) {
                if (s_nextIndexFightQueue == 5) s_nextIndexFightQueue = 0;
                s_fightIdsQueue[s_nextIndexFightQueue] = fightId;
                s_nextIndexFightQueue++;
                emit FightMatchmaker__FightRequested(
                    participants[0], nftIds[0], fightId, _fightRequest.minBet, block.timestamp
                );
            } else {
                emit FightMatchmaker__FightRequestedTo(
                    participants[0], participants[1], nftIds[0], nftIds[1], _fightRequest.minBet, block.timestamp
                );
            }
        } catch {
            if (participants[1] == address(0)) {
                revert FightMatchMaker__FightRequestFailed(
                    participants[0], nftIds[0], fightId, _fightRequest.minBet, block.timestamp
                );
            } else {
                revert FightMatchMaker__FightRequestToFailed(
                    participants[0], participants[1], nftIds[0], nftIds[1], block.timestamp
                );
            }
        }
    }

    function acceptFight(bytes32 _fightId, uint256 _nftId) external payable {
        if (msg.sender != i_PROMPT_FIGHTERS_NFT.getOwnerOf(_nftId)) {
            revert FightMatchMaker__NftNotOwnedByAccepter(msg.sender, _nftId);
        }

        Fight memory fight = getFight(_fightId);
        address[2] memory participants =
            [i_PROMPT_FIGHTERS_NFT.getOwnerOf(fight.nftOne), i_PROMPT_FIGHTERS_NFT.getOwnerOf(fight.nftTwo)];

        if (fight.state != FightState.REQUESTED) {
            revert FightMatchMaker__FightNotRequested(_fightId);
        }

        if (msg.value < fight.minBet) {
            revert FightMatchMaker__NotEnoughEthSentToAcceptFight(_fightId);
        }

        if (participants[1] != address(0) && participants[1] != msg.sender) {
            // If challengee was specified at request and sender is not challengee
            revert FightMatchMaker__AcceptingUserIsNotChallengee(msg.sender, participants[1]);
        }

        if (fight.nftTwo != 0 && fight.nftTwo != _nftId) {
            // If NFT to battle against was specified at request and accepter didn't send that NFT
            revert FightMatchMaker__NftSentDoesntMatchChallengeeNft(_nftId, fight.nftTwo);
        }

        try i_BETS_VAULT.lockBet{value: msg.value}(_fightId, msg.sender) {
            IBetsVault.BetsState memory betState = i_BETS_VAULT.getBetsState(_fightId);
            emit FightMatchmaker__FightAccepted(
                participants[0],
                participants[1],
                fight.nftOne,
                fight.nftTwo,
                betState.requesterBet,
                msg.value,
                block.timestamp
            );
        } catch {
            revert FightMatchMaker__FightAcceptFailed(msg.sender, _nftId, _fightId, msg.value, block.timestamp);
        }

        try i_FIGHT_EXECUTOR_CONTRACT.startFight(_fightId) returns (bytes32) {
            _updateFightState(_fightId, FightState.ONGOING);
            _setUserFightId(msg.sender, _fightId); // setting msg.sender -> fightId means accepter is fighting
            emit FightMatchmaker__FightStateChange(_fightId, FightState.REQUESTED, FightState.ONGOING, msg.sender);
        } catch {
            revert FightMatchMaker__FightStartFailed(_fightId);
        }
    }

    function settleFight(bytes32 _fightId, WinningAction _winner) public onlyFightExecutorOrBetsVault {
        Fight memory fight = getFight(_fightId);
        address[2] memory participants =
            [i_PROMPT_FIGHTERS_NFT.getOwnerOf(fight.nftOne), i_PROMPT_FIGHTERS_NFT.getOwnerOf(fight.nftTwo)];

        if (_winner != WinningAction.IGNORE_WINNING_ACTION) {
            address winnerAddress = _winner == WinningAction.REQUESTER_WIN ? participants[0] : participants[1];
            try i_BETS_VAULT.distributeBetsPrize(_fightId, winnerAddress) {}
            catch {
                revert FightMatchMaker__DistributeBetsPrizeFailed(_fightId, winnerAddress);
            }
        }

        try i_PROMPT_FIGHTERS_NFT.setNftsNotFighting(fight.nftOne, fight.nftTwo) {}
        catch {
            revert FightMatchMaker__SettingNftsNotFightingFailed(fight.nftOne, fight.nftTwo);
        }

        _setUserFightId(participants[0], 0); // Mark challenger as not fighting
        _setUserFightId(participants[1], 0); // Mark challengee as not fighting
        _updateFightState(_fightId, FightState.AVAILABLE);
        emit FightMatchmaker__FightStateChange(_fightId, fight.state, FightState.AVAILABLE, msg.sender);
    }

    // function cancelFight(bytes32 _fightId) external {
    //     FightState fightState = getFight(_fightId).state;
    //     if (fightState != FightState.REQUESTED) {
    //         revert FightMatchMaker__CannotCancelFight(_fightId, fightState);
    //     }
    //     settleFight(_fightId, WinningAction.IGNORE_WINNING_ACTION);
    // }

    function setNftAutomated(uint256 _nftId, bool _isAutomated) external returns (bool) {
        s_isNftAutomated[_nftId] = _isAutomated;
        return _isAutomated;
    }

    //******************** */
    // INTERNAL FUNCTIONS
    //******************** */

    function _setUserFightId(address _user, bytes32 _fightId) internal {
        s_userToFightId[_user] = _fightId;
        if (_fightId != 0) emit FightMatchmaker__UserToFightIdSet(_user, _fightId);
        else emit FightMatchmaker__UserNoLongerFighting(_user);
    }

    function _setFight(bytes32 _fightId, Fight memory _fight) internal {
        s_fightIdToFight[_fightId] = _fight;
        emit FightMatchmaker__FightIdToFightSet(_fightId, _fight);
    }

    function _updateFightState(bytes32 _fightId, FightState _fightState) internal {
        if (_fightState == FightState.AVAILABLE) {
            delete s_fightIdToFight[_fightId];
        } else {
            s_fightIdToFight[_fightId].state = _fightState;
        }
        emit FightMatchmaker__FightIdToFightSet(_fightId, s_fightIdToFight[_fightId]);
    }

    ///////////////
    // GETTERS ////
    ///////////////

    function getFightId(address _challenger, uint256 _challengerNftId, address _challengee, uint256 _challengeeNftId)
        public
        pure
        returns (bytes32)
    {
        return keccak256(abi.encode(_challenger, _challengerNftId, _challengee, _challengeeNftId));
    }

    function getFight(bytes32 _fightId) public view returns (Fight memory) {
        return s_fightIdToFight[_fightId];
    }

    function getUserCurrentFightId(address _user) public view returns (bytes32) {
        return s_userToFightId[_user];
    }

    function getUserCurrentFight(address _user) public view returns (Fight memory) {
        return s_fightIdToFight[s_userToFightId[_user]];
    }

    function getIsNftAutomated(uint256 _nftId) public view returns (bool) {
        return s_isNftAutomated[_nftId];
    }
}
