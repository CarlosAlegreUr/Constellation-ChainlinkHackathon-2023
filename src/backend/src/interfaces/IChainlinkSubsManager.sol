// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IChainlinkSubsManager
 * @author PromptFighters team: Carlos
 * @dev Interface for ChainlinkSubsManager.sol
 */
interface IChainlinkSubsManager {
    /**
     * @dev msg.sender sends LINK to the contract.
     * and the LINK is evenly distributed among all Chainlink Services subscriptions.
     */
    function fundMySubscription(uint256 amount) external;

    /**
     * @dev Sends the amount LINK back to the user's address.
     * @notice Not implemented in PoC
     */
    // function unfundMySubscription(uint256 amount) external;

    /**
     * @dev Returns how much LINK user has deposited in the contract.
     */
    function getUserSubsBalance(address user) external view returns (uint256);

    /**
     * @dev Called every time a user consumes a Chainlink service and it substracts
     * 0.5 LINK from its balance.
     */
    function userConsumesFunds() external;

    /**
     * @dev Checks if user has enough LINK sent to use the services.
     * > 15 LINK in this specific case.
     */
    function canPlay(address _user) external view returns (bool);
}
