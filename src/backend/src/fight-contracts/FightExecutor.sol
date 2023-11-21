// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IFightExecutor} from "../interfaces/IFightExecutor.sol";
import {IFightMatchmaker} from "../interfaces/IFightMatchmaker.sol";
import "../Utils.sol";

import {FunctionsClient} from "@chainlink/functions/dev/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";
import {IFunctionsSubscriptions} from "@chainlink/functions/dev/v1_0_0/interfaces/IFunctionsSubscriptions.sol";
import "@chainlink/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/vrf/VRFConsumerBaseV2.sol";

//**************************************** */
//            FOR DEVS!
// This contract might need more state
// variables or functions.
//
// Feel free to add them if you deem them
// necessary while coding.
//**************************************** */

// TODO: If contract sizes are to large, add here ChainlinkSubsManager interaction mechanisms.
// otherwise all funding checks will be done by matchmacker contract before calling the logic in
// this one.

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
contract FightExecutor is IFightExecutor, FunctionsClient, VRFConsumerBaseV2 {
    using FunctionsRequest for FunctionsRequest.Request;

    //******************************* */
    // CONTRACT'S STATE && CONSTANTS
    //******************************* */

    // External contracs interacted with
    IFightMatchmaker private immutable i_FIGHT_MATCHMAKER_CONTRACT;
    address private immutable i_LINK_TOKEN;
    VRFCoordinatorV2Interface private immutable i_VRF_COORDINATOR;

    // Chainlink Functions related
    uint64 immutable i_funcsSubsId;
    bytes32 immutable i_DON_ID;

    // Chainlink VRF related
    uint32 constant WINNER_BIT_SIZE = 1;
    uint256 constant WINNER_IS_REQUESTER = 0;
    uint256 constant WINNER_IS_ACCEPTOR = 1;
    uint64 immutable i_vrfSubsId;

    // Tracking fightIds to requests
    // First the ID will be a funcReqId and then a vftReqId
    mapping(bytes32 => bool) s_reqIsValid;
    mapping(bytes32 => bytes32) s_requestsIdToFightId;
    mapping(bytes32 => address) s_requestsIdToUser;

    constructor(IFightMatchmaker _fightMatchmakerAddress, address _router, address _vrfCoordinator)
        FunctionsClient(_router)
        VRFConsumerBaseV2(_vrfCoordinator)
    {
        i_FIGHT_MATCHMAKER_CONTRACT = _fightMatchmakerAddress;
        i_LINK_TOKEN = block.chainid == ETH_SEPOLIA_CHAIN_ID ? ETH_SEPOLIA_LINK : AVL_FUJI_LINK;
        i_VRF_COORDINATOR = VRFCoordinatorV2Interface(_vrfCoordinator);
        // Indeed if deployed in any other blockchain than SEPOLIA or FUJI it won't work.
        i_DON_ID = block.chainid == ETH_SEPOLIA_CHAIN_ID ? ETH_SEPOLIA_DON_ID : AVL_FUJI_DON_ID;

        // TODO: manage users subs with LINK token.
        // THIS SHOULD BE IN SUBS MANAGER CONTRACT AND EXECUTOR CHECKS THIS STUFF
        // WITH IT SO A i_SUBS_MANAGER state variable is required in case of
        // eventually not using inheritance.
        // i_vrfSubsId = i_VRF_COORDINATOR.createSubscription();
        // i_VRF_COORDINATOR.addConsumer(i_vrfSubsId, address(this));

        // i_funcsSubsId = IFunctionsSubscriptions(_router).createSubscription();
        // IFunctionsSubscriptions(_router).addConsumer(i_funcsSubsId, address(this));

        // TODO: delete this update it properly
        i_vrfSubsId = 0;
        i_funcsSubsId = 0;
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

    /**
     * @dev Checks that the user is not expecting the contract to encode args.
     * Checks user has provided a non empty URL object.
     * Checks that user is using the valid fight script.
     */
    modifier checkChainlinkFuncsParams(ChainlinkFuncsGist memory cfParam) {
        require(
            cfParam.encryptedSecretsUrls.length > 0 && cfParam.donHostedSecretsVersion == 0,
            "Only gists service supported here."
        );
        require(cfParam.bytesArgs.length == 0, "We don't use off-chain encoded data here.");
        require(
            keccak256(abi.encode(cfParam.source)) == GENERATE_FIGHT_SCRIPT,
            "Thats not a PromptFighters fight execution file."
        );
        _;
    }

    //******************** */
    // EXTERNAL FUNCTIONS
    //******************** */

    /**
     * @notice Send a simple request sendRequest()
     *
     * TODO: maybe _cfParam should be passed as memory?
     */
    function startFight(bytes32 _fightId, ChainlinkFuncsGist calldata _cfParam)
        external
        onlyFightMatchmaker
        checkChainlinkFuncsParams(_cfParam)
        returns (bytes32 requestId)
    {
        FunctionsRequest.Request memory req;
        req.initializeRequestForInlineJavaScript(_cfParam.source);
        req.addSecretsReference(_cfParam.encryptedSecretsUrls);
        if (_cfParam.args.length > 0) req.setArgs(_cfParam.args); // Args are NFT prompts.

        bytes32 lastRequestId = _sendRequest(req.encodeCBOR(), i_funcsSubsId, GAS_LIMIT_FIGHT_GENERATION, i_DON_ID);

        s_requestsIdToFightId[lastRequestId] = _fightId;
        s_reqIsValid[lastRequestId] = true;
        s_requestsIdToUser[lastRequestId] = msg.sender;
        return lastRequestId;
    }

    // requestRandomWords()
    function requestRandomWinner() public returns (uint256 requestId) {
        bool isSepolia = block.chainid == ETH_SEPOLIA_CHAIN_ID;
        bytes32 keyHash = isSepolia ? ETH_SEPOLIA_KEY_HASH : AVL_FUJI_KEY_HASH;
        uint16 requConfirmations = isSepolia ? ETH_SEPOLIA_REQ_CONFIRIMATIONS : AVL_FUJI_REQ_CONFIRIMATIONS;
        uint32 callbackGasLimit = isSepolia ? ETH_SEPOLIA_CALLBACK_GAS_LIMIT : AVL_FUJI_CALLBACK_GAS_LIMIT;

        // Will revert if subscription is not set and funded.
        requestId = i_VRF_COORDINATOR.requestRandomWords(
            keyHash, i_vrfSubsId, requConfirmations, callbackGasLimit, WINNER_BIT_SIZE
        );

        emit FightExecutor__VrfReqSent(requestId, block.timestamp);
        bytes32 reqIdHash = keccak256(abi.encode(requestId));
        s_reqIsValid[reqIdHash] = true;
        return requestId;
    }

    //******************** */
    // INTERNAL FUNCTIONS
    //******************** */

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

        if (err.length == 0) {
            // Success, call VRF to generate winner
            uint256 newReqId = requestRandomWinner();
            delete s_requestsIdToUser[requestId];
            _updateReqIdToFightId(requestId, keccak256(abi.encode(newReqId)));

            // From this event front-end will parse the stories generated.
            emit FightExecutor__FuncsResponse(requestId, response, block.timestamp);
        } else {
            // Failure
            emit FightExecutor__FuncsError(requestId, err, block.timestamp);
        }
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
     * @param _requestId returned by requestRandomWinner().
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

        i_FIGHT_MATCHMAKER_CONTRACT.setFightState(fightId, IFightMatchmaker.FightState.AVAILABLE, winnerBit);

        emit FightExecutor__VrfWinnerIs(fightId, winnerBit, block.timestamp);
    }

    //******************** */
    // PRIVATE FUNCTIONS
    //******************** */

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
