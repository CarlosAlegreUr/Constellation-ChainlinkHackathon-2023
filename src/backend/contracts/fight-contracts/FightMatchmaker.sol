// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IFightMatchmaker} from "../interfaces/IFightMatchmaker.sol";
import {IFightExecutor} from "../interfaces/IFightExecutor.sol";
import {IBetsVault} from "../interfaces/IBetsVault.sol";
import {ICcipNftBridge} from "../interfaces/ICcipNftBridge.sol";

import {ChainlinkFuncsGist} from "../Utils.sol";
import {LinkTokenInterface} from "@chainlink/shared/interfaces/LinkTokenInterface.sol";
import {ILogAutomation} from "../interfaces/IAutomation.sol";
import {IAutomationRegistrar} from "../interfaces/IAutomation.sol";
import {KeeperRegistry2_1} from "@chainlink/automation/v2_1/KeeperRegistry2_1.sol";
// import {IAutomationForwarder} from "@chainlink/automation/interfaces/IAutomationForwarder.sol";

/**
 *            FOR DEVS!
 *  This contract might need more state
 *  variables or functions.
 *
 *  Feel free to add them if you deem them
 *  necessary while coding. If so, mark them with a comment saying NEW.
 */

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
contract FightMatchmaker is IFightMatchmaker, ILogAutomation {
    //******************** */
    // CONTRACT'S STATE
    //******************** */

    // [ External contracts interacted with ]

    IFightExecutor private immutable i_FIGHT_EXECUTOR_CONTRACT;
    IBetsVault private immutable i_BETS_VAULT;
    ICcipNftBridge private immutable i_PROMPT_FIGHTERS_NFT;

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
    mapping(uint256 nftId => uint256 automationBalance) private s_nftAutomationBalance;
    // For now, every fight you do in automated mode will have the same amount of bet.
    mapping(uint256 => uint256) private s_automatedNftBet;
    mapping(uint256 => uint256) private s_automatedNftMinBet;
    // This mapping is treated as an array. For cheaper computation
    // every uint8 is an index and it maps to an nft id.

    // @TODO:Change to a normal array if I'm wrong cause I'm not sure.
    mapping(uint8 => uint256) private s_nftsAutomated; // BORRAR!!
    uint256[AUTOMATED_NFTS_ALLOWED] private s_automatedNfts;
    // Whenever someone requests a fight acceptable by anyone then it's added to this array.
    bytes32[AUTOMATED_NFTS_ALLOWED] private s_fightIdsQueue;
    mapping(bytes32 fight => bool isAutomated) private s_isfightAutomated;
    uint8 s_nextIndexFightQueue;
    uint8 fightQueueEmptyIndex = AUTOMATED_NFTS_ALLOWED; // default to impossible index
    // uint8[AUTOMATED_NFTS_ALLOWED] s_emptyIndexes = [0,1,2,3,4]

    ///////////////////////
    // AUTOMATION /////////
    ///////////////////////

    LinkTokenInterface public immutable i_link;
    IAutomationRegistrar public immutable i_registrar;
    KeeperRegistry2_1 public immutable i_registry;
    address private automationForwarder;
    uint256 constant AUTOMATION_BALANCE_THRESHOLD = 0.001 ether; // ESTO HAY QUE VERLO, PORQUE DEPENDERÁ DE SI ESTAMOS EN SEPOLIA O FUJI, ENTIENDO

    function checkLog(Log calldata log, bytes memory)
        external
        pure
        returns (bool upkeepNeeded, bytes memory performData)
    {
        // ENTIENDO QUE ESTO NO HARÁ FALTA, PORQUE HABREMOS DESCUBIERTO CÓMO INDICAR QUE FightMatchmaker__FightRequested ES
        // EL EVENTO QUE DESENCADENE LA AUTOMATIZACIÓN, PERO DE MOMENTO LO DEJO ASÍ
        // if (log.topics[0] == keccak256("FightMatchmaker__FightRequested(address,uint256,bytes32,uint256,uint256)")) {
        //     upkeepNeeded = true;
        // }

        upkeepNeeded = true;
        // uint256 nftId = uint256(log.topics[1]);
        bytes32 fightId = log.topics[2];
        // performData = abi.encode(nftId, fightId);
        performData = abi.encode(fightId);
    }

    function performUpkeep(bytes calldata performData) external {
        require(msg.sender == automationForwarder, "Only AutomationForwarder can perform upkeep.");
        bytes32 fightId = abi.decode(performData, bytes32);
        uint8 randIndex = uint8(uint256(fightId) % AUTOMATED_NFTS_ALLOWED);
        uint256 accepterNft = getFight(fightId).nftTwo; // Takes a value if requester specified challengee NFT (even though they didn't specify challengee address), 0 otherwise

        if (accepterNft != 0) {
            if (getIsNftAutomated(accepterNft)) {
                // AHORA VEO QUE ESTA COMPROBACIÓN LA HICE EN acceptFight (NO TENGO CLARO DÓNDE ES MEJOR)
                acceptFight(fightId, accepterNft);
            } else {
                revert FightMatchMaker__ChallengeeNftNotAutomated(accepterNft);
            }
        } else {
            for (uint8 i = randIndex; i < AUTOMATED_NFTS_ALLOWED; i++) {
                // hay que ver si el NFT automatizado tiene una apuesta lo suficientemente alta para aceptar la apuesta del requester
                if (getFight(fightId).minBet <= s_automatedNftBet[s_automatedNfts[i]]) {
                    accepterNft = s_automatedNfts[i];
                    break;
                }
            }
            for (uint8 i; i < randIndex; i++) {
                if (accepterNft != 0) break;
                if (getFight(fightId).minBet <= s_automatedNftBet[s_automatedNfts[i]]) {
                    accepterNft = s_automatedNfts[i];
                }
            }

            if (accepterNft != 0) {
                acceptFight(fightId, accepterNft);
            } else {
                revert FightMatchMaker__NoAutomatedNftHasHighEnoughBet(fightId);
            }
        }
    }

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
        ICcipNftBridge _promptFightersNftAddress,
        LinkTokenInterface _link,
        KeeperRegistry2_1 _registry, // Sepolia: 0x86EFBD0b6736Bed994962f9797049422A3A8E8Ad
        IAutomationRegistrar _registrar, // Sepolia: 0xb0E49c5D0d05cbc241d68c05BC5BA1d1B7B72976
        IAutomationRegistrar.RegistrationParams memory _params,
        ILogAutomation.LogTriggerConfig memory _triggerConfig
    ) {
        i_FIGHT_EXECUTOR_CONTRACT = _fightExecutorAddress;
        i_BETS_VAULT = _betsVaultAddress;
        i_PROMPT_FIGHTERS_NFT = _promptFightersNftAddress;
        i_link = _link;
        i_registrar = _registrar;
        i_registry = _registry;
        _params.triggerConfig = abi.encode(
            _triggerConfig.contractAddress, // DIRECCIÓN DE ESTE CONTRATO FIGHTMATCHMAKER
            _triggerConfig.filterSelector, // 2 - para que tenga en cuenta la fightId (creo)
            _triggerConfig.topic0, // FIRMA DEL EVENTO: keccak256("FightMatchmaker__FightRequested(address,uint256,bytes32,uint256,uint256)")
            _triggerConfig.topic1,
            _triggerConfig.topic2, // fightId
            _triggerConfig.topic3
        );
        i_link.approve(address(i_registrar), _params.amount);
        uint256 upkeepID = i_registrar.registerUpkeep(_params);
        if (upkeepID != 0) {
            automationForwarder = address(i_registry.getForwarder(upkeepID));
        } else {
            revert("Chainlink upkeep registration: auto-approve disabled");
        }
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
                if (fightQueueEmptyIndex < AUTOMATED_NFTS_ALLOWED) {
                    // If a slot in the queue has become available
                    s_fightIdsQueue[fightQueueEmptyIndex] = fightId;
                    s_isfightAutomated[fightId] = true;
                } else {
                    if (s_nextIndexFightQueue == AUTOMATED_NFTS_ALLOWED) {
                        // If nextIndex is max reset to 0
                        s_nextIndexFightQueue = 0;
                    }
                    s_fightIdsQueue[s_nextIndexFightQueue] = fightId;
                    s_isfightAutomated[fightId] = true;
                    s_nextIndexFightQueue++;
                }
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

    function acceptFight(bytes32 _fightId, uint256 _nftId) public payable {
        uint256 accepterBet;
        Fight memory fight = getFight(_fightId);
        uint256[2] fightingNftIds = [fight.nftOne, _nftId]; // TODO: ESTO PUEDE QUE NO SEA MUY EFICIENTE EN CUANTO A GAS - REVISAR?

        if (fight.state != FightState.REQUESTED) {
            revert FightMatchMaker__FightNotRequested(_fightId);
        }

        if (fight.nftTwo != 0 && fight.nftTwo != fightingNftIds[1]) {
            // If NFT to battle against was specified at request and accepter/upkeep didn't send that NFT
            revert FightMatchMaker__NftSentDoesntMatchChallengeeNft(fightingNftIds[1], fight.nftTwo);
        }

        if (msg.sender != automationForwarder) {
            if (msg.sender != i_PROMPT_FIGHTERS_NFT.getOwnerOf(fightingNftIds[1])) {
                revert FightMatchMaker__NftNotOwnedByAccepter(msg.sender, fightingNftIds[1]);
            }

            address[2] memory participants =
                [i_PROMPT_FIGHTERS_NFT.getOwnerOf(fightingNftIds[0]), i_PROMPT_FIGHTERS_NFT.getOwnerOf(fight.nftTwo)];

            if (msg.value < fight.minBet) {
                revert FightMatchMaker__NotEnoughEthSentToAcceptFight(_fightId);
            }

            if (participants[1] != address(0) && participants[1] != msg.sender) {
                // If challengee was specified at request and accepter is not challengee
                revert FightMatchMaker__AcceptingUserIsNotChallengee(msg.sender, participants[1]);
            }

            accepterBet = msg.value;
        } else {
            if (!getIsNftAutomated(fightingNftIds[1])) {
                revert FightMatchMaker__NftNotAutomated(fightingNftIds[1]);
            }

            address[2] memory participants = [
                i_PROMPT_FIGHTERS_NFT.getOwnerOf(fightingNftIds[0]),
                i_PROMPT_FIGHTERS_NFT.getOwnerOf(fightingNftIds[1])
            ];

            accepterBet = getAutomatedNftBet(_nftId);

            if (getNftAutomationBalance(fightingNftIds[1]) < accepterBet) {
                revert FightMatchMaker__NotEnoughAutomationBalanceToAcceptFight(_fightId, fightingNftIds[1]);
            }

            if (accepterBet < fight.minBet) {
                revert FightMatchMaker__NotEnoughEthSentToAcceptFight(_fightId);
            }

            _substractAutomationBalance(fightingNftIds[1], accepterBet);
        }

        try i_BETS_VAULT.lockBet{value: accepterBet}(_fightId, participants[1]) {
            IBetsVault.BetsState memory betState = i_BETS_VAULT.getBetsState(_fightId);
            emit FightMatchmaker__FightAccepted(
                participants[0],
                participants[1],
                fightingNftIds[0],
                fightingNftIds[1],
                betState.requesterBet,
                accepterBet,
                block.timestamp
            );
        } catch {
            revert FightMatchMaker__FightAcceptFailed(
                participants[1], fightingNftIds[1], _fightId, accepterBet, block.timestamp
            );
        }

        try i_FIGHT_EXECUTOR_CONTRACT.startFight(_fightId) returns (bytes32) {
            _updateFightState(_fightId, FightState.ONGOING);
            _setUserFightId(participants[1], _fightId); // setting accepter -> fightId means accepter is fighting
            emit FightMatchmaker__FightStateChange(_fightId, FightState.REQUESTED, FightState.ONGOING, participants[1]);
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
        if (getIsFightAutomated(_fightId)) _removeFightFromQueue(_fightId); // switches value in array from fightId to 0
        emit FightMatchmaker__FightStateChange(_fightId, fight.state, FightState.AVAILABLE, msg.sender);
    }

    // function cancelFight(bytes32 _fightId) external {
    //     FightState fightState = getFight(_fightId).state;
    //     if (fightState != FightState.REQUESTED) {
    //         revert FightMatchMaker__CannotCancelFight(_fightId, fightState);
    //     }
    //     settleFight(_fightId, WinningAction.IGNORE_WINNING_ACTION);
    // }

    function setNftAutomated(uint256 _nftId, bool _isAutomated, uint256 _bet, uint256 _minBet)
        external
        payable
        returns (bool)
    {
        if (msg.sender == i_PROMPT_FIGHTERS_NFT.getOwnerOf(_nftId)) {
            if (_bet == 0) revert FightMatchMaker__AutomatedBetCannotBeZero();
            s_isNftAutomated[_nftId] = _isAutomated;
            s_automatedNfts.push(_nftId);
            if (_isAutomated) {
                s_nftAutomationBalance[_nftId] += msg.value;
                s_automatedNftBet[_nftId] = _bet;
                s_automatedNftMinBet[_nftId] = _minBet;
                emit FightMatchmaker__nftAutomated(_nftId, msg.value, _bet, _minBet);
            } else {
                uint256 remainingAutomationBalance = s_nftAutomationBalance[_nftId];
                delete s_nftAutomationBalance[_nftId];
                delete s_automatedNftBet[_nftId];
                delete s_automatedNftMinBet[_nftId];
                (bool callSuccess,) = msg.sender.call.value(remainingAutomationBalance)("");
                require(callSuccess, "Remaining automation balance transfer failed");
                emit FightMatchmaker__nftAutomationCancelled(_nftId);
            }
        } else {
            revert FightMatchMaker__OnlyNFtOnwerCanSetNftAutomated();
        }
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

    function _substractAutomationBalance(uint256 _nftId, uint256 _amount) internal {
        s_nftAutomationBalance[_nftId] -= _amount;
        emit FightMatchmaker__nftAutomationBalanceUpdated(_nftId, s_nftAutomationBalance[_nftId]);
        if (s_nftAutomationBalance[_nftId] < AUTOMATION_BALANCE_THRESHOLD) {
            s_isNftAutomated[_nftId] = false;
            emit FightMatchmaker__nftAutomationCancelled(_nftId);
        }
    }

    function _removeFightFromQueue(bytes32 _fightId) internal {
        for (uint8 i; i < AUTOMATED_NFTS_ALLOWED; i++) {
            if (s_fightIdsQueue[i] == _fightId) {
                delete s_fightIdsQueue[i];
                fightQueueEmptyIndex = i;
                break;
            }
        }
    }

    // function _getFightQueueEmptyIndex() internal returns (uint8) {
    //     return fightQueueEmptyIndex;
    // }

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

    function getIsNftAutomated(uint256 _nftId) public view returns (bool) {
        return s_isNftAutomated[_nftId];
    }

    function getNftAutomationBalance(uint256 _nftId) public view returns (uint256) {
        return s_nftAutomationBalance[_nftId];
    }

    function getNftAutomatedNftBet(uint256 _nftId) public view returns (uint256) {
        return s_automatedNftBet[_nftId];
    }

    function getNftAutomatedNftMinBet(uint256 _nftId) public view returns (uint256) {
        return s_automatedNftMinBet[_nftId];
    }

    function getIsFightAutomated(bytes32 _fightId) public view returns (bool) {
        return s_isfightAutomated[_fightId];
    }
}
