// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IChainlinkSubsManager} from "../interfaces/IChainlinkSubsManager.sol";

/**
 * @title IFightExecutor
 * @author PromptFighters team: Carlos
 * @dev Interface for the FightExecutor contract.
 */
interface IFightExecutor is IChainlinkSubsManager {
    struct FightExecutor__ChainlinkServicesInitParmas {
        // VRF
        bytes32 keyHash;
        uint16 requConfirmations;
        uint32 callbackGasLimit;
        // Funtions
        uint64 funcSubsId;
        bytes32 donId;
    }

    // Check if more parameters needed for easier track of historical data in front-end graph
    event FightExecutor__FunctionsResults(bytes indexed firstEnd, bytes indexed secondEnd);

    event FightExecutor__FuncsResponse(bytes32 indexed requestId, bytes indexed response, uint256 timestamp);
    event FightExecutor__FuncsError(bytes32 indexed requestId, bytes indexed err, uint256 timestamp);

    // probably needs subId etc
    event FightExecutor__VrfReqSent(uint256 indexed requestId, uint256 timestamp);
    event FightExecutor__VrfWinnerIs(bytes32 indexed fightId, uint256 indexed winnerBit, uint256 timestamp);

    // Calls Chainlink Functions, in the return calls VRF and in VRF return sets winner.
    /**
     * @dev This function must always be called by `FightMatchmaker` and then it starts
     * the fight process via Chainlink Functions.
     *
     */
    function startFight(bytes32 fightId) external returns (bytes32 requestId);
}
