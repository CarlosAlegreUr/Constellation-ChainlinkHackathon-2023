// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IFightMatchmaker} from "../interfaces/IFightMatchmaker.sol";
import {IFightExecutor} from "../interfaces/IFightExecutor.sol";
import {IBetsVault} from "../interfaces/IBetsVault.sol";

import {ICcipNftBridge} from "../interfaces/ICcipNftBridge.sol";
import {ReferencesInitializer} from "../ReferencesInitializer.sol";

import {IAutomationRegistrar} from "../interfaces/IAutomation.sol";
import {IAutomationRegistry} from "../interfaces/IAutomation.sol";
import {LogTriggerConfig} from "../interfaces/IAutomation.sol";

import {ILogAutomation} from "@chainlink/automation/interfaces/ILogAutomation.sol";
import {Log} from "@chainlink/automation/interfaces/ILogAutomation.sol";
import {IAutomationForwarder} from "@chainlink/automation/interfaces/IAutomationForwarder.sol";

import {LinkTokenInterface} from "@chainlink/shared/interfaces/LinkTokenInterface.sol";

import "../Utils.sol";

/**
 * @title FightMatchmaker
 * @author PromptFighters dev team:  @CarlosAlegreUr and @arynyestos
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
contract FightMatchmaker is IFightMatchmaker, ILogAutomation, ReferencesInitializer {
    //******************************* */
    // CONTRACT'S STATE && CONSTANTS
    //******************************* */

    // [ External contracts interacted with ]

    // They are in practice immuntable once initializeReferences()
    // is executed by deployer
    IFightExecutor private i_FIGHT_EXECUTOR_CONTRACT;
    IBetsVault private i_BETS_VAULT;
    ICcipNftBridge private i_PROMPT_FIGHTERS_NFT;

    LinkTokenInterface public immutable i_LINK;
    IAutomationForwarder private immutable i_AUTOMATION_FORWARDER;

    // [ Matchmaking - state ]

    mapping(bytes32 => Fight) private s_fightIdToFight;
    // As a user can only have 1 fight at a time we only need this mapping
    // to check if the user is fighting or not.
    // If ID == 0 then user is not fighting neither looking for one.
    // @notice Make sure address 0 can never appear while creating fightIds, revert if so.
    mapping(address => bytes32) private s_userToFightId;

    // [ Automated matchmaking - state - for now only 1 playe can be automated]

    uint256 s_nftIdAutomated;
    uint256 private s_nftAutomationBalance;
    // For now, every fight you do in automated mode will have the same amount of bet.
    uint256 private s_automatedNftBet;
    uint256 private s_automatedNftMinBet;
    // If balance goes below this threshold automation is stopped and NFT is deleted from automation.
    uint256 immutable i_AUTOMATION_BALANCE_THRESHOLD;

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

    modifier requestFightChecks(FightRequest calldata fightReq) {
        // Nfts are on chain
        if (!i_PROMPT_FIGHTERS_NFT.isNftOnChain(fightReq.challengerNftId)) {
            revert FightMatchMaker__NftNotOnThisChain(fightReq.challengerNftId, block.chainid);
        }
        if (!i_PROMPT_FIGHTERS_NFT.isNftOnChain(fightReq.challengeeNftId)) {
            revert FightMatchMaker__NftNotOnThisChain(fightReq.challengeeNftId, block.chainid);
        }

        // Ownership checks
        if (msg.sender != i_PROMPT_FIGHTERS_NFT.getOwnerOf(fightReq.challengerNftId)) {
            revert FightMatchMaker__NftNotOwnedByChallenger(msg.sender, fightReq.challengerNftId);
        }
        if (
            fightReq.challengeeNftId != 0
                && fightReq.challengee != i_PROMPT_FIGHTERS_NFT.getOwnerOf(fightReq.challengeeNftId)
        ) {
            revert FightMatchMaker__NftNotOwnedByChallengee(fightReq.challengee, fightReq.challengeeNftId);
        }

        // Sender is not fighting check
        if (getUserCurrentFight(msg.sender).state != FightState.AVAILABLE) {
            revert FightMatchMaker__OnlyRequesWhenAvailable();
        }
        _;
    }

    //******************** */
    // CONSTRUCTOR
    //******************** */

    constructor(
        LinkTokenInterface _link,
        IAutomationRegistry _registry,
        IAutomationRegistrar _registrar,
        IAutomationRegistrar.RegistrationParams memory _params,
        uint256 _automationBalanceThreshold
    ) {
        i_LINK = _link;

        // Automation registration
        _params.triggerConfig = abi.encode(
            address(this), // Listen to this contract
            2, // Binary 010, considering only topic2 (fightId)
            keccak256("FightMatchmaker__FightRequested(address,uint256,bytes32,uint256,uint256)"), // Listen for this event
            0x0, // If you don't want to filter on a specific nftId
            0x0, // If you don't want to filter on a specific fightId
            0x0 // If you don't want to filter on a specific bet
        );

        i_LINK.approve(address(_registrar), _params.amount);
        uint256 upkeepID = _registrar.registerUpkeep(_params);
        if (upkeepID == 0) {
            revert("Chainlink upkeep registration: auto-approve disabled");
        }

        // Get forwarder
        i_AUTOMATION_FORWARDER = _registry.getForwarder(upkeepID);

        // Set threshold so contract doesnt run out of funds while automating
        i_AUTOMATION_BALANCE_THRESHOLD = _automationBalanceThreshold;
    }

    function initializeReferences(address[] memory _references) external override initializeActions {
        i_FIGHT_EXECUTOR_CONTRACT = IFightExecutor(_references[0]);
        i_BETS_VAULT = IBetsVault(_references[1]);
        i_PROMPT_FIGHTERS_NFT = ICcipNftBridge(_references[2]);
    }

    //******************************/
    // EXTERNAL & PUBLIC FUNCTIONS
    //******************************/

    // Fight State Management

    function requestFight(FightRequest calldata _fightReq) external payable requestFightChecks(_fightReq) {
        address[2] memory participants = [msg.sender, _fightReq.challengee];
        uint256[2] memory nftIds = [_fightReq.challengerNftId, _fightReq.challengeeNftId];

        bytes32 fightId = getFightId(participants[0], nftIds[0], participants[1], nftIds[1]);

        try i_BETS_VAULT.lockBet{value: msg.value}(fightId, msg.sender) {
            // Updates user state and emits event for front-end tracking
            _setUserFightId(msg.sender, fightId);

            Fight memory f = Fight({
                nftRequester: nftIds[0],
                nftAcceptor: nftIds[1],
                minBet: _fightReq.minBet,
                acceptanceDeadline: _fightReq.minBet,
                startedAt: block.timestamp,
                state: FightState.REQUESTED
            });
            s_fightIdToFight[fightId] = f;

            emit FightMatchmaker__FightRequested(
                msg.sender, _fightReq.challengerNftId, fightId, msg.value, block.timestamp
            );
        } catch {
            if (participants[1] == address(0)) {
                revert FightMatchMaker__FightReqFailed(
                    participants[0], nftIds[0], fightId, _fightReq.minBet, block.timestamp
                );
            } else {
                revert FightMatchMaker__FightReqToFailed(
                    participants[0], participants[1], nftIds[0], nftIds[1], block.timestamp
                );
            }
        }
    }

    function acceptFight(bytes32 _fightId, uint256 _nftId) public payable {
        Fight memory fight = getFight(_fightId);
        bool automationCalling = msg.sender == address(i_AUTOMATION_FORWARDER);
        uint256 acceptorBet = automationCalling ? s_automatedNftBet : msg.value;

        _acceptFightChecks(fight, _fightId, _nftId, acceptorBet, automationCalling);

        address acceptor = i_PROMPT_FIGHTERS_NFT.getOwnerOf(fight.nftAcceptor);
        // Lock funds and start fight execution
        try i_BETS_VAULT.lockBet{value: acceptorBet}(_fightId, acceptor) {
            IBetsVault.BetsState memory betState = i_BETS_VAULT.getBetsState(_fightId);
            emit FightMatchmaker__FightAccepted(
                i_PROMPT_FIGHTERS_NFT.getOwnerOf(fight.nftRequester),
                i_PROMPT_FIGHTERS_NFT.getOwnerOf(fight.nftAcceptor),
                fight.nftRequester,
                _nftId,
                betState.requesterBet,
                acceptorBet,
                block.timestamp
            );
        } catch {
            revert FightMatchMaker__FightAcceptFailed(acceptor, _nftId, _fightId, acceptorBet, block.timestamp);
        }

        try i_FIGHT_EXECUTOR_CONTRACT.startFight(_fightId) returns (bytes32) {
            _updateFightState(_fightId, FightState.ONGOING);
            // setting accepter -> fightId means accepter is fighting
            _setUserFightId(acceptor, _fightId);
            emit FightMatchmaker__FightStateChange(_fightId, FightState.REQUESTED, FightState.ONGOING, acceptor);
        } catch {
            revert FightMatchMaker__FightStartFailed(_fightId);
        }
    }

    function _acceptFightChecks(
        Fight memory _fight,
        bytes32 _fightId,
        uint256 _nftId,
        uint256 acceptorBet,
        bool _automationCalling
    ) private {
        // Figh state checkings

        if (_fight.state != FightState.REQUESTED) {
            revert FightMatchMaker__FightNotRequested(_fightId);
        }

        // Ownership checkings

        address[2] memory participants = [
            i_PROMPT_FIGHTERS_NFT.getOwnerOf(_fight.nftRequester),
            i_PROMPT_FIGHTERS_NFT.getOwnerOf(_fight.nftAcceptor)
        ];

        if (_automationCalling) {
            // If specified an acceptor
            if (participants[1] != address(0) && participants[1] != i_PROMPT_FIGHTERS_NFT.getOwnerOf(_nftId)) {
                revert FightMatchMaker__AcceptingUserIsNotChallengee(msg.sender, participants[1]);
            }

            // If specified NFT on request
            if (_fight.nftAcceptor != 0 && _nftId != _fight.nftAcceptor) {
                revert FightMatchMaker__NftSentDoesntMatchChallengeeNft(_nftId, _fight.nftAcceptor);
            }
        } else {
            // You must be the owner of the nft you wanna use in the fight
            if (msg.sender != i_PROMPT_FIGHTERS_NFT.getOwnerOf(_nftId)) {
                revert FightMatchMaker__NftNotOwnedByAccepter(msg.sender, _nftId);
            }

            // If specified NFT on request
            if (_fight.nftAcceptor != 0 && msg.sender != i_PROMPT_FIGHTERS_NFT.getOwnerOf(_nftId)) {
                revert FightMatchMaker__NftSentDoesntMatchChallengeeNft(_nftId, _fight.nftAcceptor);
            }

            // If specified an acceptor
            if (participants[1] != address(0) && participants[1] != msg.sender) {
                revert FightMatchMaker__AcceptingUserIsNotChallengee(msg.sender, participants[1]);
            }
        }

        // Bets checkings

        if (acceptorBet < _fight.minBet) {
            revert FightMatchMaker__NotEnoughEthSentToAcceptFight(_fightId);
        }
        _checkAndUpdateAutomationBalance(_automationCalling);
    }

    function settleFight(bytes32 _fightId, WinningAction _winner) public onlyFightExecutorOrBetsVault {
        Fight memory fight = getFight(_fightId);
        address[2] memory participants =
            [i_PROMPT_FIGHTERS_NFT.getOwnerOf(fight.nftRequester), i_PROMPT_FIGHTERS_NFT.getOwnerOf(fight.nftAcceptor)];

        if (_winner != WinningAction.IGNORE_WINNING_ACTION) {
            address winnerAddress = _winner == WinningAction.REQUESTER_WIN ? participants[0] : participants[1];
            try i_BETS_VAULT.distributeBetsPrize(_fightId, winnerAddress) {}
            catch {
                revert FightMatchMaker__DistributeBetsPrizeFailed(_fightId, winnerAddress);
            }
        }

        i_PROMPT_FIGHTERS_NFT.setIsNftFighting(fight.nftRequester, false);
        i_PROMPT_FIGHTERS_NFT.setIsNftFighting(fight.nftAcceptor, false);

        _setUserFightId(participants[0], 0); // Mark challenger as not fighting
        _setUserFightId(participants[1], 0); // Mark challengee as not fighting
        _updateFightState(_fightId, FightState.AVAILABLE);

        emit FightMatchmaker__FightStateChange(_fightId, fight.state, FightState.AVAILABLE, msg.sender);
    }

    // Fight Automation

    function setNftAutomated(uint256 _nftId, uint256 _bet, uint256 _minBet, uint256 _linkFunds) external {
        require(s_nftIdAutomated == 0, "An NFT is already automated, we only allow 1 at a time for now.");
        require(_linkFunds >= i_AUTOMATION_BALANCE_THRESHOLD, "You must send more LINK to use automation.");
        require(msg.sender == i_PROMPT_FIGHTERS_NFT.getOwnerOf(_nftId), "You must own the NFT to automate it.");

        s_nftIdAutomated = _nftId;
        s_automatedNftBet = _bet;
        s_automatedNftMinBet = _minBet;
        s_nftAutomationBalance += _linkFunds;

        bool success = i_LINK.transferFrom(msg.sender, address(this), _linkFunds);
        require(success, "Fail transfering LINK automation funding.");
    }

    function checkLog(Log calldata log, bytes memory)
        external
        view
        returns (bool upkeepNeeded, bytes memory performData)
    {
        upkeepNeeded = true;

        bytes32 fightId = log.topics[2];
        Fight memory f = s_fightIdToFight[fightId];

        // The automated NFT fits the fight
        if (s_nftIdAutomated != f.nftAcceptor && f.nftAcceptor != 0) {
            upkeepNeeded = false;
        }

        // If its a personalized challenge, then owner of automated NFT can accept if he is the challenged one
        address expectedAcceptor = i_PROMPT_FIGHTERS_NFT.getOwnerOf(f.nftAcceptor);
        if (expectedAcceptor != address(0) && i_PROMPT_FIGHTERS_NFT.getOwnerOf(s_nftIdAutomated) != expectedAcceptor) {
            upkeepNeeded = false;
        }
        // The bet is acceptable for challenger
        if (f.minBet < s_automatedNftBet) {
            upkeepNeeded = false;
        }

        performData = abi.encode(fightId);
    }

    function performUpkeep(bytes calldata performData) external {
        require(msg.sender == address(i_AUTOMATION_FORWARDER), "Only AutomationForwarder can perform upkeep.");
        bytes32 fightId = abi.decode(performData, (bytes32));
        acceptFight(fightId, s_nftIdAutomated);
    }

    //******************** */
    // INTERNAL FUNCTIONS
    //******************** */

    function _setUserFightId(address _user, bytes32 _fightId) internal {
        s_userToFightId[_user] = _fightId;
        if (_fightId != 0) {
            emit FightMatchmaker__UserToFightIdSet(_user, _fightId);
        } else {
            emit FightMatchmaker__UserNoLongerFighting(_user);
        }
    }

    function _updateFightState(bytes32 _fightId, FightState _fightState) internal {
        if (_fightState == FightState.AVAILABLE) {
            delete s_fightIdToFight[_fightId];
        } else {
            s_fightIdToFight[_fightId].state = _fightState;
        }
        emit FightMatchmaker__FightIdToFightSet(_fightId, s_fightIdToFight[_fightId]);
    }

    function _checkAndUpdateAutomationBalance(bool _needUpdate) internal {
        if (_needUpdate) {
            if (s_automatedNftBet < s_nftAutomationBalance) {
                s_nftAutomationBalance -= s_automatedNftBet;
                emit FightMatchmaker__nftAutomationBalanceUpdated(s_nftIdAutomated, s_nftAutomationBalance);
            }

            if (s_nftAutomationBalance < i_AUTOMATION_BALANCE_THRESHOLD) {
                emit FightMatchmaker__nftAutomationCancelled(s_nftIdAutomated);
                delete s_nftIdAutomated;
            }
        }
    }

    //************************ */
    // VIEW / PURE FUNCTIONS
    //************************ */

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

    function getNftsFromFightId(bytes32 _fightId) public view returns (uint256, uint256) {
        return (s_fightIdToFight[_fightId].nftRequester, s_fightIdToFight[_fightId].nftAcceptor);
    }

    function getNftsPromptsFromFightId(bytes32 _fightId) external view returns (string memory, string memory) {
        return (
            i_PROMPT_FIGHTERS_NFT.getPromptOf(s_fightIdToFight[_fightId].nftRequester),
            i_PROMPT_FIGHTERS_NFT.getPromptOf(s_fightIdToFight[_fightId].nftAcceptor)
        );
    }

    function getUserCurrentFightId(address _user) public view returns (bytes32) {
        return s_userToFightId[_user];
    }

    function getUserCurrentFight(address _user) public view returns (Fight memory) {
        return s_fightIdToFight[s_userToFightId[_user]];
    }
}
