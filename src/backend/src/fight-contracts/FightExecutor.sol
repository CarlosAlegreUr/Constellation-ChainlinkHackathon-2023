// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IFightExecutor} from "../interfaces/IFightExecutor.sol";
import {IFightMatchmaker} from "../interfaces/IFightMatchmaker.sol";

import {FunctionsClient} from "@chainlink/functions/dev/v1_0_0/FunctionsClient.sol";
import {FunctionsRequest} from "@chainlink/functions/dev/v1_0_0/libraries/FunctionsRequest.sol";
import "@chainlink/interfaces/VRFCoordinatorV2Interface.sol";
import "@chainlink/vrf/VRFConsumerBaseV2.sol";

//************************************** */
//            FOR DEVS!
// This contract might need more state
// variables or interface functions.
//
// Feel free to add them if you deem it
// necessary.
//************************************** */

//@dev TODO: COMPLETE CHAINLINK FUNCTIONS AND VRF INTEGRATION TO THE CONTRACT
//@dev TODO: MAYBE JUST MAKE FIGHT MATCHMAKER AND EXECUTOR INHERITANCE IF CONTRACT IS NOT TOO LARGE TO BE DEPLOYED
contract FightExecutor is IFightExecutor, FunctionsClient, VRFConsumerBaseV2 {
    using FunctionsRequest for FunctionsRequest.Request;

    //******************** */
    // CONTRACT'S STATE
    //******************** */

    // External contracs interacted with
    IFightExecutor private immutable i_FIGHT_MATCHMAKER_CONTRACT;

    bytes private constant s_apiCallDenoFile = "";

    constructor(IFightExecutor _fightMatchmakerAddress, address _router, address _vrfCoordinator)
        FunctionsClient(_router)
        VRFConsumerBaseV2(_vrfCoordinator)
    {
        i_FIGHT_MATCHMAKER_CONTRACT = _fightMatchmakerAddress;
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

    // These parameter will probably change. The parameters should be the ones that Chainlink Functions
    // need in the deno code it will execute.
    function startFight(address[2] calldata _participants, uint256[2] calldata _nftIds) external onlyFightMatchmaker {
        // Call Chainlink Functions
    }

    //******************** */
    // INTERNAL FUNCTIONS
    //******************** */

    // Chainlink Functions return funcition, initiates a VRF request based on the return.
    function fulfillRequest(bytes32 requestId, bytes memory response, bytes memory err) internal override {}

    // Chainlink VRF return funcition: eventually must call setFightState() on FightMatchmaker.
    function fulfillRandomWords(uint256 requestId, uint256[] memory randomWords) internal override {}

    // Create methods to fund a susbsciption to VRF. Every time you request a fight you must fund the subscription.

    //******************** */
    // VIEW/PURE FUNCTIONS
    //******************** */

    function getFunctionsFile() public pure returns (bytes memory) {
        return s_apiCallDenoFile;
    }
}
