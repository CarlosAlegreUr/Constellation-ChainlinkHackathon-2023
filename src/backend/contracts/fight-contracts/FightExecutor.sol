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
 * @author PromptFighters team: @CarlosAlegreUr
 * @dev This contract has all the logic for executing a fight.
 * Whenever FightMatchmaker calls this contracts startFight() it triggers Chainlink Functions
 * to generate the fight lore and then automatically on its response VRF is triggered to generate a
 * fair winner.
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

    // All addresses are in practice intializable once initializeReferences() is called.
    IFightMatchmaker private i_FIGHT_MATCHMAKER_CONTRACT;
    VRFCoordinatorV2Interface private immutable i_VRF_COORDINATOR;

    // Tracking fightIds to hashes of requestsIds
    // First the ID will be a funcReqId and then a vrfReqId
    // As they are different type we hash them keccack256() to have a common bytes32 type.
    mapping(bytes32 => bool) private s_reqIsValid;
    mapping(bytes32 => bytes32) private s_requestsIdToFightId;
    mapping(bytes32 => address) private s_requestsIdToUser;

    // Chainlink Functions related
    bytes32 private immutable i_donId;

    // Chainlink VRF related
    uint32 private constant WINNER_BIT_SIZE = 1;
    uint256 private constant WINNER_IS_REQUESTER = 0;
    uint256 private constant WINNER_IS_ACCEPTOR = 1;
    bytes32 private immutable i_keyHash;
    uint16 private immutable i_requConfirmations;
    uint32 private immutable i_callbackGasLimit;

    //*****************/
    // CONSTRUCTOR
    //**************** */

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

    /**
     * @dev Docs at ReferencesInitializer.sol
     */
    function initializeReferences(address[] calldata _references) external override initializeActions {
        i_FIGHT_MATCHMAKER_CONTRACT = IFightMatchmaker(_references[0]);
        emit ReferencesInitialized(_references, address(this), block.timestamp);
    }

    //******************** */
    // MODIFIERS
    //******************** */

    /**
     * @dev Checks if msg.sender is `FightMatchmaker` contract.
     * If not then reverts.
     */
    modifier onlyFightMatchmaker() {
        require(msg.sender == address(i_FIGHT_MATCHMAKER_CONTRACT), "Only FightExecutor can call this.");
        _;
    }

    //******************** */
    // EXTERNAL FUNCTIONS
    //******************** */

    /**
     * @dev Docs at IFightExecutor.sol
     */
    function startFight(bytes32 _fightId) external onlyFightMatchmaker {
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
        emit FightExecutor__FightStarted(_fightId, lastRequestId, nftRequesterPrompt, nftAcceptorPrompt);
    }

    //******************** */
    // INTERNAL FUNCTIONS
    //******************** */

    /**
     * @dev Emits an event with latest result/error from Chainlink Functions.
     * If not erros given then it calls VRF.
     *
     * @notice The request must exists.
     *
     * @param requestId The request ID, set by startFight() functions request.
     * @param response Aggregated response from the user code. Now its just 1 general story.
     * If HTTP-API calls could last > 9s then it would be 2 fight stories with 2 differnet outcomes
     * and the one showed to the user would be decided upon the VRF generated value.
     * @param err Aggregated error from the user code or from the execution pipeline
     */
    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {
        require(s_reqIsValid[requestId], "Unexpected funcs request ID.");
        delete s_reqIsValid[requestId];

        // @dev TODO: ADD A WAY OF MARKING FALIED RESPONSES
        // Event emitted on Failure
        emit FightExecutor__FightStoryFuncsError(requestId, err, block.timestamp);

        // Success, call VRF to generate winner
        uint256 newReqId = _requestRandomWinner();
        _userConsumesFunds(s_requestsIdToUser[requestId]);
        delete s_requestsIdToUser[requestId];
        _updateReqIdToFightId(requestId, keccak256(abi.encode(newReqId)));

        // From this event front-end will parse the story generated.
        emit FightExecutor__FightStoryFuncsResponse(requestId, response, block.timestamp);
    }

    /**
     * @dev This functions decides a winner with a module operation to generate a winning bit.
     *
     * Then it calls `FightMatchmaker` setFightState() that will update properly the fight's state
     * and eventually call BetsVault to distribute the prize.
     *
     * @notice The request must exists.
     * @notice The amount of random words returns must always be 1.
     *
     * @param _requestId returned by _requestRandomWinner().
     * @param _randomWords an array with the random number generated.
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

        emit FightExecutor__FightResultVrfWinnerIs(fightId, winnerBit, block.timestamp);
    }

    //******************** */
    // PRIVATE FUNCTIONS
    //******************** */

    /**
     * @dev Function called by Chainlink Functions fullfilRequest(), it triggers
     * the VRF process.
     */
    function _requestRandomWinner() private returns (uint256 requestId) {
        requestId = i_VRF_COORDINATOR.requestRandomWords(
            i_keyHash, i_vrfSubsId, i_requConfirmations, i_callbackGasLimit, WINNER_BIT_SIZE
        );

        bytes32 reqIdHash = keccak256(abi.encode(requestId));
        s_reqIsValid[reqIdHash] = true;

        emit FightExecutor__FightResultVrfReqSent(i_vrfSubsId, requestId, block.timestamp);
        return requestId;
    }

    /**
     * @dev Updates the s_requestsIdToFightId mapping.
     * If newReq == 0 that means it deletes all values.
     */
    function _updateReqIdToFightId(bytes32 _oldReq, bytes32 _newReq) private returns (bytes32 fightId) {
        fightId = s_requestsIdToFightId[_oldReq];
        delete s_requestsIdToFightId[_oldReq];

        if (_newReq != bytes32(0)) {
            s_requestsIdToFightId[_newReq] = fightId;
        } else {
            // This "else" might not be needed. Added as precaution.
            delete s_requestsIdToFightId[_newReq];
        }
    }

    //************************ */
    // VIEW / PURE FUNCTIONS
    //************************ */

    // Getters

    function getReqIsValid(bytes32 req) public view returns (bool) {
        return s_reqIsValid[req];
    }

    function getRequestsIdToFightId(bytes32 requestId) public view returns (bytes32) {
        return s_requestsIdToFightId[requestId];
    }

    function getRequestsIdToUser(bytes32 requestId) public view returns (address) {
        return s_requestsIdToUser[requestId];
    }

    function getChainlinkServicesParams()
        public
        view
        returns (IFightExecutor.FightExecutor__ChainlinkServicesInitParmas memory)
    {
        return IFightExecutor.FightExecutor__ChainlinkServicesInitParmas(
            i_keyHash, i_requConfirmations, i_callbackGasLimit, i_vrfSubsId, i_donId
        );
    }

    function getWinnerBitSize() public pure returns (uint32) {
        return WINNER_BIT_SIZE;
    }

    function getWinnerIsRequester() public pure returns (uint256) {
        return WINNER_IS_REQUESTER;
    }

    function getWinnerIsAcceptor() public pure returns (uint256) {
        return WINNER_IS_ACCEPTOR;
    }
}
