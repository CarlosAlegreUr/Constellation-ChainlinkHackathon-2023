// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IFightMatchmaker} from "../interfaces/IFightMatchmaker.sol";
import {IFightExecutor} from "../interfaces/IFightExecutor.sol";
import {IBetsVault} from "../interfaces/IBetsVault.sol";
import {ICcipNftBridge} from "../interfaces/ICcipNftBridge.sol";
import {ReferencesInitializer} from "../ReferencesInitializer.sol";

import {IAutomationRegistrar} from "../interfaces/IAutomation.sol";
import {IAutomationRegistry} from "../interfaces/IAutomation.sol";
import {ILogAutomation} from "@chainlink/automation/interfaces/ILogAutomation.sol";
import {Log} from "@chainlink/automation/interfaces/ILogAutomation.sol";
import {IAutomationForwarder} from "@chainlink/automation/interfaces/IAutomationForwarder.sol";

import {LinkTokenInterface} from "@chainlink/shared/interfaces/LinkTokenInterface.sol";

import "../Utils.sol";

/**
 * @title FightMatchmaker
 * @author PromptFighters dev team: @CarlosAlegreUr and @arynyestos
 * @dev Handles matchmaking processes in the game. The matchmaking involves two main steps:
 *
 * 1. requestFight(): Initiates a fight request and emits an event for off-chain detection.
 * 2. acceptFight(): Used to accept a fight request and also starts the fight execution.
 *
 * The contract supports automated matchmaking only for 1 NFT simultaneously.
 * Eeach player is engaged in only one fight at a time.
 */
contract FightMatchmaker is IFightMatchmaker, ILogAutomation, ReferencesInitializer {
    //******************************* */
    // CONTRACT'S STATE && CONSTANTS
    //******************************* */

    // All addresses are in practice intializable once initializeReferences() is called.
    IFightExecutor private i_FIGHT_EXECUTOR_CONTRACT;
    IBetsVault private i_BETS_VAULT;
    ICcipNftBridge private i_PROMPT_FIGHTERS_NFT;
    IAutomationRegistry private i_AUTOMATION_REGISTRY;
    uint256 private i_UPKEEP_ID;

    LinkTokenInterface private immutable i_LINK;
    IAutomationForwarder private i_AUTOMATION_FORWARDER;

    // Matchmaking-state
    mapping(bytes32 => Fight) private s_fightIdToFight;
    // As a user can only have 1 fight at a time we only need the following
    // mapping to check if the user is fighting or not.
    // If ID == 0 then user is neither fighting neither requesting one.
    // @notice Crazy edge case: Make sure address 0 can never appear while creating fightIds, revert if so.
    mapping(address => bytes32) private s_userToFightId;

    // Automated matchmaking - state - for now only 1 player can be automated

    // When Chainlink Functions allows for events tracking, matchmaking can be done
    // and escalated off-chain via parsing events.
    uint256 private s_nftIdAutomated;
    uint256 private s_nftAutomationBalance;
    // For now, every fight you do in automated mode will bet the same amount.
    uint256 private s_automatedNftBet;
    uint256 private s_automatedNftMinBet;
    // If balance goes below this threshold, automation is stopped and NFT is deleted from automation.
    // This is a simple brute solution so automation always works once funded.
    uint256 private immutable i_AUTOMATION_BALANCE_THRESHOLD;

    // In case Chainlink Services fail and users funds are locked,
    // after 1 day they will be able to retrieve them.
    uint256 private constant APOCALIPSIS_SAFETY_NET = 1 days;

    //******************** */
    // MODIFIERS
    //******************** */

    /**
     * @dev Checks if msg.sender is `FightExecutor` contract or `BetsVault` contract.
     * If not then revert.
     *
     * @notice VRF for some reason we couldn't figure out is not fullfilling requests
     * in Sepolia, so we made the DEPLOYER for this PoC to be able to finish fights and distribute prizes.
     */
    modifier onlyFightExecutor() {
        require(
            msg.sender == address(i_FIGHT_EXECUTOR_CONTRACT) /*SP_MARK_START*/ || msg.sender == DEPLOYER, /*SP_MARK_END*/
            "Only FightExecutor or BetsVault can call this."
        );
        _;
    }

    /**
     * @dev All checks that mut be carried before requesting a fight.
     * Nfts are on this chain.
     * Participants are owners.
     * Can't fight yourself and can only look for 1 fight or figh 1 fight at a time.
     */
    modifier requestFightChecks(FightRequest calldata fightReq) {
        // You can't fight yourself
        require(msg.sender != fightReq.challengee, "FightMatchMaker__CantFightYourself");

        // Sender is not fighting or already requesting check
        require(s_userToFightId[msg.sender] == bytes32(0), "FightMatchMaker__ChallengeeIsFighting");

        // Nfts are on chain
        require(
            i_PROMPT_FIGHTERS_NFT.getIsNftOnChain(fightReq.challengerNftId)
                && i_PROMPT_FIGHTERS_NFT.getIsNftOnChain(fightReq.challengeeNftId),
            "FightMatchMaker__NftNotOnThisChain"
        );

        // Ownership checks
        require(
            msg.sender == i_PROMPT_FIGHTERS_NFT.getOwnerOf(fightReq.challengerNftId),
            "FightMatchMaker__NftNotOwnedByChallenger"
        );

        if (fightReq.challengeeNftId != 0) {
            require(
                fightReq.challengee == i_PROMPT_FIGHTERS_NFT.getOwnerOf(fightReq.challengeeNftId),
                "FightMatchMaker__NftNotOwnedByChallengee"
            );
        }

        _;
    }

    //******************** */
    // CONSTRUCTOR
    //******************** */

    constructor(LinkTokenInterface _link, uint256 _automationBalanceThreshold) {
        i_LINK = _link;
        i_AUTOMATION_BALANCE_THRESHOLD = _automationBalanceThreshold;
    }

    /**
     * @dev Initializes the contract, must be called immediately after construction by DEPLOYER.
     *
     * @notice For some reason initializing the Automation is only working on Sepolia testnet.
     */
    function initializeReferencesAndAutomation(
        address[] memory _references,
        IAutomationRegistry _registry,
        IAutomationRegistrar _registrar,
        IAutomationRegistrar.RegistrationParams memory _params
    ) external initializeActions {
        /*SP_MARK_START*/
        // @dev For some reason in Fuji is not working, cant check upkeep id after set
        if (block.chainid == ETH_SEPOLIA_CHAIN_ID) {
            // Automation registration complete params that require address(this)
            _params.upkeepContract = address(this);
            _params.adminAddress = address(this);
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
            require(upkeepID != 0, "Chainlink upkeep registration: auto-approve disabled");

            // Get&Set forwarder
            i_UPKEEP_ID = upkeepID;
            i_AUTOMATION_FORWARDER = _registry.getForwarder(upkeepID);
            i_AUTOMATION_REGISTRY = _registry;
            emit FightMatchmaker__AutomatonRegistered(upkeepID);
        }
        /*SP_MARK_END*/

        (bool success,) = address(this).call(abi.encodeWithSignature("initializeReferences(address[])", _references));
        require(success, "Failure intializing references");
    }

    // TODO: delete after testing
    function setForwarderDuh(address forwarder) external {
        require(msg.sender == DEPLOYER);
        i_AUTOMATION_FORWARDER = IAutomationForwarder(forwarder);
    }

    // TODO: delete after testing
    uint256 public st_upkeepId;

    // TODO: delete after testing
    function setUpkeepId(uint256 uid) external {
        require(msg.sender == DEPLOYER);
        st_upkeepId = uid;
    }

    /**
     * @notice In this contract this can only be called from initializeReferencesAndAutomation()
     */
    function initializeReferences(address[] memory _references) public override {
        require(msg.sender == address(this), "Only callable by itself.");
        i_FIGHT_EXECUTOR_CONTRACT = IFightExecutor(_references[0]);
        i_BETS_VAULT = IBetsVault(_references[1]);
        i_PROMPT_FIGHTERS_NFT = ICcipNftBridge(_references[2]);
        emit ReferencesInitialized(_references, address(this), block.timestamp);
    }

    //******************************/
    // EXTERNAL & PUBLIC FUNCTIONS
    //******************************/

    // Fight State Management

    /**
     * @dev Docs at IFightMatchmaker.sol
     */
    function requestFight(FightRequest calldata _fightReq) external payable requestFightChecks(_fightReq) {
        address[2] memory participants = [msg.sender, _fightReq.challengee];
        uint256[2] memory nftIds = [_fightReq.challengerNftId, _fightReq.challengeeNftId];

        bytes32 fightId = getFightId(participants[0], nftIds[0], participants[1], nftIds[1]);
        require(fightId != bytes32(0), "This fight can't be created as the 0 value is essential for contract's logic.");

        try i_BETS_VAULT.lockBet{value: msg.value}(fightId, msg.sender) {
            // Updates user state and emits event for front-end tracking
            _setUserFightId(msg.sender, fightId);

            Fight memory f = Fight({
                nftRequester: nftIds[0],
                nftAcceptor: nftIds[1],
                minBet: _fightReq.minBet,
                acceptanceDeadline: _fightReq.acceptanceDeadline,
                startedAt: block.timestamp,
                state: FightState.REQUESTED
            });
            s_fightIdToFight[fightId] = f;

            // TODO: use FightRequestedTo event when address or nft specified
            emit FightMatchmaker__FightRequested(
                msg.sender, _fightReq.challengerNftId, fightId, msg.value, block.timestamp
            );
        } catch {
            if (participants[1] == address(0)) {
                revert("FightMatchMaker FightReqFailed");
            } else {
                revert("FightMatchMaker FightReqFailed");
            }
        }
    }

    /**
     * @dev Docs at IFightMatchmaker.sol
     */
    function acceptFight(bytes32 _fightId, uint256 _nftId) public payable {
        Fight memory fight = getFight(_fightId);
        bool automationCalling = msg.sender == address(i_AUTOMATION_FORWARDER);
        uint256 acceptorBet = automationCalling ? s_automatedNftBet : msg.value;

        _acceptFightChecks(fight, _nftId, acceptorBet, automationCalling);

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
            revert("FightMatchMaker__FightAcceptFailed");
        }

        try i_FIGHT_EXECUTOR_CONTRACT.startFight(_fightId) {
            _updateFightState(_fightId, FightState.ONGOING);
            // setting accepter -> fightId means accepter is fighting
            _setUserFightId(acceptor, _fightId);
            i_PROMPT_FIGHTERS_NFT.setIsNftFighting(fight.nftRequester, true);
            i_PROMPT_FIGHTERS_NFT.setIsNftFighting(fight.nftAcceptor, true);
            emit FightMatchmaker__FightStateChange(_fightId, FightState.REQUESTED, FightState.ONGOING, acceptor);
        } catch {
            revert("FightMatchMaker__FightStartFailed");
        }
    }

    /**
     * @dev Docs at IFightMatchmaker.sol
     */
    function settleFight(bytes32 _fightId, WinningAction _winner) public onlyFightExecutor {
        Fight memory fight = getFight(_fightId);
        address[2] memory participants =
            [i_PROMPT_FIGHTERS_NFT.getOwnerOf(fight.nftRequester), i_PROMPT_FIGHTERS_NFT.getOwnerOf(fight.nftAcceptor)];

        address winnerAddress = _winner == WinningAction.REQUESTER_WIN ? participants[0] : participants[1];
        try i_BETS_VAULT.distributeBetsPrize(_fightId, winnerAddress) {}
        catch {
            revert("FightMatchMaker__DistributeBetsPrizeFailed");
        }

        i_PROMPT_FIGHTERS_NFT.setIsNftFighting(fight.nftRequester, false);
        i_PROMPT_FIGHTERS_NFT.setIsNftFighting(fight.nftAcceptor, false);

        _setUserFightId(participants[0], 0); // Mark challenger as not fighting
        _setUserFightId(participants[1], 0); // Mark challengee as not fighting
        _updateFightState(_fightId, FightState.AVAILABLE);

        emit FightMatchmaker__FightStateChange(_fightId, fight.state, FightState.AVAILABLE, msg.sender);
    }

    /**
     * @dev Docs at IFightMatchmaker.sol
     */
    function cancelFight(bytes32 _fightId) external {
        IFightMatchmaker.Fight memory fightDetails = getFight(_fightId);

        // If can't unlock it will revert
        _checkUnlockConditions(fightDetails);

        // Will only work if msg.sender betted on _fightId
        i_BETS_VAULT.unlockAndRetrieveBet(_fightId, msg.sender);
    }

    // Fight Automation

    function setNftAutomated(uint256 _nftId, uint256 _bet, uint256 _minBet, uint96 _linkFunds) external {
        require(s_nftIdAutomated == 0, "An NFT is already automated, we only allow 1 at a time for now.");
        require(_linkFunds >= i_AUTOMATION_BALANCE_THRESHOLD, "You must send more LINK to use automation.");
        require(msg.sender == i_PROMPT_FIGHTERS_NFT.getOwnerOf(_nftId), "You must own the NFT to automate it.");

        s_nftIdAutomated = _nftId;
        s_automatedNftBet = _bet;
        s_automatedNftMinBet = _minBet;
        s_nftAutomationBalance += _linkFunds;

        bool success = i_LINK.transferFrom(msg.sender, address(this), _linkFunds);
        require(success, "Fail transfering LINK automation funding.");
        i_LINK.approve(address(i_AUTOMATION_REGISTRY), _linkFunds);
        i_AUTOMATION_REGISTRY.addFunds(i_UPKEEP_ID, _linkFunds);
    }

    /**
     * @dev Called by Automation forwarder.
     * If there is an NFT automated and can accept the fight it calls
     * acceptFight() via performUpkeep().
     */

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

        // The NFT is not fighting
        if (i_PROMPT_FIGHTERS_NFT.getIsNftFighting(s_nftIdAutomated)) {
            upkeepNeeded = false;
        }

        performData = abi.encode(fightId);
    }

    /**
     * @dev Allow Automation to start fights.
     */
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
            }

            if (s_nftAutomationBalance < i_AUTOMATION_BALANCE_THRESHOLD) {
                delete s_nftIdAutomated;
            }
        }
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

    /**
     * @dev Checks fight can be started.
     * Caller is allowed.
     * Caller owns nft and nft is allowed.
     * Fight is actually in REQUESTED state.
     * Bets are vald.
     * If automation user still has funds to automate actions.
     */
    function _acceptFightChecks(Fight memory _fight, uint256 _nftId, uint256 acceptorBet, bool _automationCalling)
        private
    {
        // Figh state checkings

        require(_fight.state == FightState.REQUESTED, "FightMatchMaker__FightNotRequested");

        // Ownership checkings

        address[2] memory participants =
            [i_PROMPT_FIGHTERS_NFT.getOwnerOf(_fight.nftRequester), i_PROMPT_FIGHTERS_NFT.getOwnerOf(_nftId)];

        if (_automationCalling) {
            // If specified an acceptor
            if (participants[1] != address(0)) {
                require(
                    participants[1] == i_PROMPT_FIGHTERS_NFT.getOwnerOf(_nftId),
                    "FightMatchMaker__AcceptingUserIsNotChallengee"
                );
            }

            // If specified NFT on request
            if (_fight.nftAcceptor != 0) {
                require(_nftId == _fight.nftAcceptor, "FightMatchMaker__NftSentDoesntMatchChallengeeNft");
            }
        } else {
            // You must be the owner of the nft you wanna use in the fight
            require(msg.sender == i_PROMPT_FIGHTERS_NFT.getOwnerOf(_nftId), "FightMatchMaker__NftNotOwnedByAccepter");

            // If specified NFT on request
            if (_fight.nftAcceptor != 0) {
                require(
                    msg.sender == i_PROMPT_FIGHTERS_NFT.getOwnerOf(_nftId), "FightMatchMaker__NftNotOwnedByAccepter"
                );
            }

            // If specified an acceptor
            if (participants[1] != address(0)) {
                require(participants[1] == msg.sender, "FightMatchMaker__AcceptingUserIsNotChallengee");
            }
        }

        // Acceptor is not already in a battle or requesting one
        require(s_userToFightId[participants[1]] == bytes32(0), "FightMatchMaker__ChallengeeIsFighting");

        // Bets checkings

        require(acceptorBet >= _fight.minBet, "FightMatchMaker__NotEnoughEthSentToAcceptFight");

        // Funds provided to execute Chainlink Serivces provided by any of the players
        require(
            i_FIGHT_EXECUTOR_CONTRACT.canPlay(participants[0]) || i_FIGHT_EXECUTOR_CONTRACT.canPlay(participants[1]),
            "FightMatchMaker__AnyFighterHasEnoughFunds"
        );

        _checkAndUpdateAutomationBalance(_automationCalling);
    }

    //************************ */
    // VIEW / PURE FUNCTIONS
    //************************ */

    //************************ */
    // LOTS OF GETTERS (probably some of them are not needed)
    //************************ */

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

    function getNftsOwnersFromFightId(bytes32 _fightId) external view returns (address, address) {
        return (
            i_PROMPT_FIGHTERS_NFT.getOwnerOf(s_fightIdToFight[_fightId].nftRequester),
            i_PROMPT_FIGHTERS_NFT.getOwnerOf(s_fightIdToFight[_fightId].nftAcceptor)
        );
    }

    function getUserCurrentFightId(address _user) public view returns (bytes32) {
        return s_userToFightId[_user];
    }

    function getUserCurrentFight(address _user) public view returns (Fight memory) {
        return s_fightIdToFight[s_userToFightId[_user]];
    }

    function getFightExecutorContract() public view returns (address) {
        return address(i_FIGHT_EXECUTOR_CONTRACT);
    }

    function getBetsVault() public view returns (address) {
        return address(i_BETS_VAULT);
    }

    function getPromptFightersNft() public view returns (address) {
        return address(i_PROMPT_FIGHTERS_NFT);
    }

    function getLinkTokenInterface() public view returns (address) {
        return address(i_LINK);
    }

    function getAutomationForwarder() public view returns (address) {
        return address(i_AUTOMATION_FORWARDER);
    }

    function getFightIdToFight(bytes32 fightId) public view returns (Fight memory) {
        return s_fightIdToFight[fightId];
    }

    function getUserToFightId(address user) public view returns (bytes32) {
        return s_userToFightId[user];
    }

    function getNftIdAutomated() public view returns (uint256) {
        return s_nftIdAutomated;
    }

    function getNftAutomationBalance() public view returns (uint256) {
        return s_nftAutomationBalance;
    }

    function getAutomationBalanceThreshold() public view returns (uint256) {
        return i_AUTOMATION_BALANCE_THRESHOLD;
    }

    function getContractUpkeepId() public view returns (uint256) {
        return i_UPKEEP_ID;
    }

    function getAutomationRegistry() public view returns (address) {
        return address(i_AUTOMATION_REGISTRY);
    }

    function getApocalipsisSafetyNet() public pure returns (uint256) {
        return APOCALIPSIS_SAFETY_NET;
    }
}
