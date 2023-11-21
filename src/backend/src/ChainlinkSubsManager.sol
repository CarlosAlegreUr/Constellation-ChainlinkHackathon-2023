// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IChainlinkSubsManager} from "./interfaces/IChainlinkSubsManager.sol";

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
 * @dev This contract... TODO
 */
contract ChainlinkSubsManager is IChainlinkSubsManager {
    uint256 constant MIN_LINK_IN_SUBS = 20 ether;
    address immutable i_LINK_TOKEN;

    // A balance of a user must be > X LINK in order to keep using our service.
    // Proper amount of LINK should be determined by testing.
    mapping(address => uint256) s_userToSubsBalance;
    mapping(address => bool) s_userCanPlay;

    constructor(address _link) {
        i_LINK_TOKEN = _link;
    }

    function fundMySubscription(uint256 amount) external {
        // Call link token address

        s_userToSubsBalance[msg.sender] += amount;
        // bool success = i_LINK_TOKEN.transferFrom(msg.sender, address(this), amount);
        // require(success, "Faild to transfer LINK.");
    }

    function unfundMySubscription(uint256 amount) external {
        s_userToSubsBalance[msg.sender] -= amount;
        // bool success = i_LINK_TOKEN.transfer(address(this), msg.sender, amount);
    }

    function getUserSubsBalance(address _user) external view returns (uint256) {
        return s_userToSubsBalance[_user];
    }

    // For simplicity every time user uses a chainlink service 1 LINK is charged.
    // In real production the price would be tested and adjusted to the actual
    // price of using chainlink functions plus a small fee to pay for a ChatGPT
    // API call.
    function userConsumesFunds() external {
        s_userToSubsBalance[msg.sender] -= 0.5 ether;
    }

    function canPlay(address _user) external view returns (bool) {
        return s_userToSubsBalance[_user] >= MIN_LINK_IN_SUBS ? true : false;
    }
}
