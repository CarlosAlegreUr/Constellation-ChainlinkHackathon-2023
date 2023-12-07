// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IChainlinkSubsManager
 * @author PromptFighters team: @CarlosAlegreUr
 * @dev Interface for ChainlinkSubsManager.sol
 */
interface IChainlinkSubsManager {
    // Events
    event ChainlinkSubsManager__SubsFunded(address indexed user, uint256 amount);

    // Functions

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
     * @dev Checks if user has enough LINK sent to use the services.
     * > 15 LINK in this specific case.
     */
    function canPlay(address _user) external view returns (bool);

    // Getters

    /**
     * @dev Returns how much LINK user has deposited in the contract.
     */
    function getUserSubsBalance(address user) external view returns (uint256);

    function getLinkTokenInterface() external view returns (address);

    function getVrfSubsId() external view returns (uint64);

    function getFuncsSubsId() external view returns (uint64);
}
