// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IChainlinkSubsManager} from "../interfaces/IChainlinkSubsManager.sol";

/**
 * @title IFightExecutor
 * @author PromptFighters team: @CarlosAlegreUr
 * @dev Interface for the FightExecutor contract.
 */
interface IFightExecutor is IChainlinkSubsManager {
    // Structs

    /**
     * @dev Params needed for intializing Chainlink Services.
     */
    struct FightExecutor__ChainlinkServicesInitParmas {
        // VRF
        bytes32 keyHash;
        uint16 requConfirmations;
        uint32 callbackGasLimit;
        // Funtions
        uint64 funcSubsId;
        bytes32 donId;
    }

    // Events

    event FightExecutor__FightStarted(
        bytes32 indexed fightId, bytes32 indexed requId, string promptRequester, string promptAcceptor
    );

    event FightExecutor__FightsStoriesGenerated(bytes indexed firstEnd, bytes indexed secondEnd);
    event FightExecutor__FightStoryFuncsResponse(bytes32 indexed requestId, bytes response, uint256 timestamp);
    event FightExecutor__FightStoryFuncsError(bytes32 indexed requestId, bytes err, uint256 timestamp);

    event FightExecutor__FightResultVrfReqSent(uint64 indexed vrfSubId, uint256 indexed requestId, uint256 timestamp);
    event FightExecutor__FightResultVrfWinnerIs(bytes32 indexed fightId, uint256 indexed winnerBit, uint256 timestamp);

    /**
     * @dev This function must always be called by `FightMatchmaker`.
     * It starts the fight execution process using Chainlink Functions requests.
     */
    function startFight(bytes32 fightId) external;

    // Getters

    function getReqIsValid(bytes32 req) external view returns (bool);

    function getRequestsIdToFightId(bytes32 requestId) external view returns (bytes32);

    function getRequestsIdToUser(bytes32 requestId) external view returns (address);

    function getChainlinkServicesParams() external view returns (FightExecutor__ChainlinkServicesInitParmas memory);

    function getWinnerBitSize() external pure returns (uint32);

    function getWinnerIsRequester() external pure returns (uint256);

    function getWinnerIsAcceptor() external pure returns (uint256);
}
