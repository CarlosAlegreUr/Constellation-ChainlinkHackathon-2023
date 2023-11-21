// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IChainlinkSubsManager
 * @author PromptFighters team: Carlos
 * @dev Interface for managing users subscriptions to our contract's use
 * of Chainlink services.
 *
 * @notice As a PoC for simplicity, every time a user consumes a Chainlink Services
 * 1 LINK is charged to him. In real wolrd production tests must be made to better adjust
 * the prices of consuming Chainlink services plus paying the OpenAI API calls.
 */
interface IChainlinkSubsManager {
    /**
     * @dev msg.sender sends LINK to the contract.
     */
    function fundMySubscription(uint256 amount) external;

    /**
     * @dev If msg.sender is not fighting, sends the LINK back to
     * the user's address.
     */
    function unfundMySubscription(uint256 amount) external;

    /**
     * @dev Returns how much LINK user has deposited in the contract.
     * Any user must have a minimum of 15 LINK to be able to play.
     * As said above this is arbitrary and further study must be done.
     */
    function getUserSubsBalance(address user) external view returns (uint256);

    /**
     * @dev Called every time a user consumes a Chainlink service and it substracts
     * 0.5 LINK from it balance.
     * As said above this is arbitrary and further study must be done.
     */
    function userConsumesFunds() external;
}
