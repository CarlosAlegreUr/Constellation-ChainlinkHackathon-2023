// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IChainlinkSubsManager} from "./interfaces/IChainlinkSubsManager.sol";
import {LinkTokenInterface} from "@chainlink/shared/interfaces/LinkTokenInterface.sol";

//**************************************** */
//            FOR DEVS!
// This contract might need more state
// variables or functions.
//
// Feel free to add them if you deem them
// necessary while coding.
//**************************************** */

/**
 * @title ChainlinkSubsManager
 * @author PromptFighters team: Carlos
 * @dev This contract manages the subscriptions funds on contracts that
 * use different Chainlink Services which require subscriptions.
 *
 * @notice This is a simplified subscriptions funds management. Each user
 * must have a minimum of 15 LINK sent to the contract in order to use its services and
 * guarantee that the contract will always have enough LINK to execute the services.
 *
 * For each services called the user spends 0.5 LINK. If the funds provided go below 15 LINK
 * the user must fund the contract again.
 *
 * @notice As this is a simple PoC, in the real life code proper testing should be made to create
 * fitting prices for different chainlink services and pronably even remove the idea of a minimum
 * required balance.
 */
contract ChainlinkSubsManager is IChainlinkSubsManager {
    //******************** */
    // CONTRACT'S STATE
    //******************** */

    uint256 constant MIN_LINK_IN_SUBS = 15 ether;
    LinkTokenInterface private immutable i_LINK_TOKEN;

    mapping(address => uint256) s_userToSubsBalance;

    constructor(LinkTokenInterface _link) {
        i_LINK_TOKEN = _link;
    }

    //******************** */
    // EXTERNAL FUNCTIONS
    //******************** */

    function fundMySubscription(uint256 amount) external {
        s_userToSubsBalance[msg.sender] += amount;
        bool success = i_LINK_TOKEN.transferFrom(msg.sender, address(this), amount);
        require(success, "Faild to transfer LINK.");
    }

    function unfundMySubscription(uint256 amount) external {
        s_userToSubsBalance[msg.sender] -= amount;
        bool success = i_LINK_TOKEN.transfer(msg.sender, amount);
        require(success, "Faild to transfer LINK.");
    }

    function userConsumesFunds() external {
        s_userToSubsBalance[msg.sender] -= 0.5 ether;
    }

    function canPlay(address _user) external view returns (bool) {
        return s_userToSubsBalance[_user] >= MIN_LINK_IN_SUBS ? true : false;
    }

    function getUserSubsBalance(address _user) external view returns (uint256) {
        return s_userToSubsBalance[_user];
    }
}
