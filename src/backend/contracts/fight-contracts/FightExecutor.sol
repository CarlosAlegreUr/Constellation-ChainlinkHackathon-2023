// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IFightExecutor} from "../interfaces/IFightExecutor.sol";
import {IFightMatchmaker} from "../interfaces/IFightMatchmaker.sol";
import "../Utils.sol";

import {ChainlinkSubsManager} from "../ChainlinkSubsManager.sol";
import {ReferencesInitializer} from "../ReferencesInitializer.sol";

import {LinkTokenInterface} from "@chainlink/shared/interfaces/LinkTokenInterface.sol";
import {FunctionsClient} from "@chainlink/functions/dev/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";
import {IFunctionsSubscriptions} from "@chainlink/functions/dev/v1_0_0/interfaces/IFunctionsSubscriptions.sol";
import "@chainlink/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/vrf/VRFConsumerBaseV2.sol";

/**
 * @title FightExecutor
 * @author PromptFighters team: Carlos
 * @dev This contract all the logic for executing a fight.
 * Whenever FightMatchmaker calls this contract then it uses Chainlink Functions
 * to generate the fight lore and then uses VRF to generate a fair winner.
 *
 * As of now, for simplicity, the chances of winning are 50% for each player.
 * Future plans are to use speific NFT traits to redistribute probability based on
 * fighter descriptions and how they relate to each other.
 */
contract FightExecutor is
    IFightExecutor,
    ChainlinkSubsManager,
    FunctionsClient,
    VRFConsumerBaseV2,
    ReferencesInitializer
{
    using FunctionsRequest for FunctionsRequest.Request;

    //******************************* */
    // CONTRACT'S STATE && CONSTANTS
    //******************************* */

    // External contracs interacted with
    IFightMatchmaker private i_FIGHT_MATCHMAKER_CONTRACT;
    VRFCoordinatorV2Interface private immutable i_VRF_COORDINATOR;

    // Tracking fightIds to requests
    // First the ID will be a funcReqId and then a vftReqId
    mapping(bytes32 => bool) s_reqIsValid;
    mapping(bytes32 => bytes32) s_requestsIdToFightId;
    mapping(bytes32 => address) s_requestsIdToUser;

    // Chainlink Functions related
    bytes32 immutable i_donId;

    // Chainlink VRF related
    uint32 constant WINNER_BIT_SIZE = 1;
    uint256 constant WINNER_IS_REQUESTER = 0;
    uint256 constant WINNER_IS_ACCEPTOR = 1;
    bytes32 immutable i_keyHash;
    uint16 immutable i_requConfirmations;
    uint32 immutable i_callbackGasLimit;

    constructor(
        address _funcsRouter,
        address _vrfCoordinator,
        FightExecutor__ChainlinkServicesInitParmas memory _cfiParams
    )
        ChainlinkSubsManager(_funcsRouter, _cfiParams.funcSubsId, _vrfCoordinator)
        FunctionsClient(_funcsRouter)
        VRFConsumerBaseV2(_vrfCoordinator)
    {
        i_donId = _cfiParams.donId;

        i_VRF_COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        i_keyHash = _cfiParams.keyHash;
        i_requConfirmations = _cfiParams.requConfirmations;
        i_callbackGasLimit = _cfiParams.callbackGasLimit;
    }

    function initializeReferences(address[] calldata _references) external override initializeActions {
        i_FIGHT_MATCHMAKER_CONTRACT = IFightMatchmaker(_references[0]);
    }

    //******************** */
    // MODIFIERS
    //******************** */

    /**
     * @dev Checks if msg.sender is `FightMatchmaker` contract.
     * If not then revert.
     */
    modifier onlyFightMatchmaker() {
        require(msg.sender == address(i_FIGHT_MATCHMAKER_CONTRACT), "Only FightExecutor can call this.");
        _;
    }

    //******************** */
    // EXTERNAL FUNCTIONS
    //******************** */

    /**
     * @notice Send a simple request sendRequest()
     */
    function startFight(bytes32 _fightId) external onlyFightMatchmaker returns (bytes32 requestId) {
        FunctionsRequest.Request memory req;

        req.initializeRequestForInlineJavaScript(FIGHT_GENERATION_SCRIPT_MOCK);
        req.addSecretsReference(FUNCTIONS_URL_SECRETS_ENDPOINT);

        string[] memory args = new string[](2);
        (string memory nftRequesterPrompt, string memory nftAcceptorPrompt) =
            i_FIGHT_MATCHMAKER_CONTRACT.getNftsPromptsFromFightId(_fightId);
        args[0] = nftRequesterPrompt;
        args[1] = nftAcceptorPrompt;
        req.setArgs(args);

        bytes32 lastRequestId = _sendRequest(req.encodeCBOR(), i_funcsSubsId, GAS_LIMIT_FIGHT_GENERATION, i_donId);

        s_requestsIdToFightId[lastRequestId] = _fightId;
        s_reqIsValid[lastRequestId] = true;
        s_requestsIdToUser[lastRequestId] = msg.sender;
        return lastRequestId;
    }

    //******************** */
    // INTERNAL FUNCTIONS
    //******************** */

    // TODO: simulate functions from server because story generations lasts more than 9s
    /**
     * @dev Emits an event with latest result/error from Chainlink Functions.
     * If not erros given then it calls VFR.
     * Either response or error parameter will be set, but never both
     *
     * @notice The request must exists.
     *
     * @param requestId The request ID, returned by startFight()
     * @param response Aggregated response from the user code
     * @param err Aggregated error from the user code or from the execution pipeline
     */
    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
        require(s_reqIsValid[requestId], "Unexpected funcs request ID.");
        delete s_reqIsValid[requestId];

        // @dev TODO: ADD A WAY OF MARKING FALIED RESPONSES

        // Success, call VRF to generate winner
        uint256 newReqId = _requestRandomWinner();
        _userConsumesFunds(s_requestsIdToUser[requestId]);
        delete s_requestsIdToUser[requestId];
        _updateReqIdToFightId(requestId, keccak256(abi.encode(newReqId)));

        // From this event front-end will parse the stories generated.
        emit FightExecutor__FuncsResponse(requestId, response, block.timestamp);
        // Failure
        emit FightExecutor__FuncsError(requestId, err, block.timestamp);
    }

    /**
     * @dev This functions decides a winner with module operation to generate a winning bit.
     *
     * Then it calls `FightMatchmaker` setFightState() with the fightId, AVAILABLE fight state,
     * and the winner bit so `FightMatchmaker` eventually calls BetsVault and distribute the
     * rewards.
     *
     * @notice The request must exists.
     * @notice The amount of random words returns must always be 1.
     *
     * @param _requestId returned by _requestRandomWinner().
     * @param _randomWords an array with the random numbers generated.
     */
    function fulfillRandomWords(uint256 _requestId, uint256[] memory _randomWords) internal override {
        require(_randomWords.length == WINNER_BIT_SIZE, "Vrf amount of words not valid.");

        bytes32 reqIdHash = keccak256(abi.encode(_requestId));
        require(s_reqIsValid[reqIdHash], "Unexpected vrf request ID.");
        delete s_reqIsValid[reqIdHash];

        bytes32 fightId = _updateReqIdToFightId(reqIdHash, bytes32(0));

        uint256 bit = _randomWords[0] % 2;
        uint256 winnerBit = bit == 0 ? WINNER_IS_REQUESTER : WINNER_IS_ACCEPTOR;

        i_FIGHT_MATCHMAKER_CONTRACT.settleFight(fightId, IFightMatchmaker.WinningAction(winnerBit));

        emit FightExecutor__VrfWinnerIs(fightId, winnerBit, block.timestamp);
    }

    //******************** */
    // PRIVATE FUNCTIONS
    //******************** */

    // requestRandomWords()
    function _requestRandomWinner() private returns (uint256 requestId) {
        requestId = i_VRF_COORDINATOR.requestRandomWords(
            i_keyHash, i_vrfSubsId, i_requConfirmations, i_callbackGasLimit, WINNER_BIT_SIZE
        );

        emit FightExecutor__VrfReqSent(requestId, block.timestamp);
        bytes32 reqIdHash = keccak256(abi.encode(requestId));
        s_reqIsValid[reqIdHash] = true;
        return requestId;
    }

    /**
     * @dev Updates the s_requestsIdToFightId mappnig.
     * If newReq == 0 that means it deletes all values.
     */
    function _updateReqIdToFightId(bytes32 _oldReq, bytes32 _newReq) private returns (bytes32 fightId) {
        fightId = s_requestsIdToFightId[_oldReq];
        delete s_requestsIdToFightId[_oldReq];

        if (_newReq != bytes32(0)) {
            s_requestsIdToFightId[_newReq] = fightId;
        } else {
            // This else might not be needed. Added as precaution.
            delete s_requestsIdToFightId[_newReq];
        }
    }
}
