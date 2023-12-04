// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IChainlinkSubsManager} from "./interfaces/IChainlinkSubsManager.sol";

import {LinkTokenInterface} from "@chainlink/shared/interfaces/LinkTokenInterface.sol";

import {IFunctionsSubscriptions} from "@chainlink/functions/dev/v1_0_0/interfaces/IFunctionsSubscriptions.sol";
import "@chainlink/interfaces/VRFCoordinatorV2Interface.sol";

import "./Utils.sol";

/**
 * @title ChainlinkSubsManager
 * @author PromptFighters team: @CarlosAlegreUr
 * @dev This contract manages the subscriptions funds on contracts that
 * use different Chainlink Services which require multiple subscriptions.
 * In this case only VRF and Functions.
 *
 * @notice This is a simplified subscriptions funds management. Each user
 * must have a minimum of 0.8 LINK sent to the contract in order to use its services and
 * guarantee that the contract will always have enough LINK to execute the services.
 *
 * For each services called the user spends 0.5 LINK. If the funds provided go below 10 LINK
 * the user must fund the subscriptions again.
 *
 * @notice As this is a simple PoC, in the real life code proper testing should be made to create
 * fitting prices for different chainlink services and pronably even remove the idea of a minimum
 * required balance and a "pay as you use" schema.
 *
 * NOTE: There is most likely a more composable and cleaner way of managing the subscriptions
 * to Chainlink Services of all the contracts. But time is cathing up and we need to ship the project.
 */
contract ChainlinkSubsManager is IChainlinkSubsManager {
    //******************** */
    // CONTRACT'S STATE
    //******************** */

    uint256 private constant MIN_LINK_IN_SUBS = 0.8 ether;
    LinkTokenInterface private immutable i_LINK_TOKEN;

    mapping(address => uint256) private s_userToSubsBalance;

    uint64 internal immutable i_funcsSubsId;
    address private immutable i_funcsSubsAccess;

    uint64 internal immutable i_vrfSubsId;
    address private immutable i_vrfSubsAccess;

    constructor(address _funcsRouter, uint64 _funcSubsId, address _vrfCoordinator) {
        i_LINK_TOKEN = block.chainid == ETH_SEPOLIA_CHAIN_ID
            ? LinkTokenInterface(ETH_SEPOLIA_LINK)
            : LinkTokenInterface(AVL_FUJI_LINK);

        i_vrfSubsId = VRFCoordinatorV2Interface(_vrfCoordinator).createSubscription();
        VRFCoordinatorV2Interface(_vrfCoordinator).addConsumer(i_vrfSubsId, address(this));

        i_funcsSubsId = _funcSubsId;

        // @dev Doesn't work, needs to accept TermsOfService first, so far this is only
        // possible trhough Chainlink's API.
        // IFunctionsSubscriptions(_funcsRouter).createSubscription();
        // IFunctionsSubscriptions(_funcsRouter).addConsumer(i_funcsSubsId, address(this));

        i_funcsSubsAccess = _funcsRouter;
        i_vrfSubsAccess = _vrfCoordinator;
    }

    //******************** */
    // EXTERNAL FUNCTIONS
    //******************** */

    function fundMySubscription(uint256 amount) external {
        s_userToSubsBalance[msg.sender] += amount;
        bool success = i_LINK_TOKEN.transferFrom(msg.sender, address(this), amount);
        require(success, "Faild to transfer LINK.");

        i_LINK_TOKEN.transferAndCall(i_funcsSubsAccess, amount / 2, abi.encode(i_funcsSubsId));
        i_LINK_TOKEN.transferAndCall(i_vrfSubsAccess, amount / 2, abi.encode(i_vrfSubsId));

        emit ChainlinkSubsManager__SubsFunded(msg.sender, amount);
    }

    // @notice Not implemented for PoC
    // function unfundMySubscription(uint256 amount) external {
    //     s_userToSubsBalance[msg.sender] -= amount;
    //     bool success = i_LINK_TOKEN.transfer(msg.sender, amount);
    //     require(success, "Faild to transfer LINK.");
    // }

    //******************** */
    // PUBLIC FUNCTIONS
    //******************** */

    function canPlay(address _user) public view returns (bool) {
        return s_userToSubsBalance[_user] >= MIN_LINK_IN_SUBS ? true : false;
    }

    //******************** */
    // INTERNAL FUNCTIONS
    //******************** */

    /**
     * @dev Called every time a user consumes a Chainlink service and it substracts
     * 0.5 LINK from its balance.
     *
     * @notice In tests so far functions consumes ~0.25 LINK and VRF nodes
     * are not available so we don't know.
     */
    function _userConsumesFunds(address _user) internal {
        s_userToSubsBalance[_user] -= 0.5 ether;
    }

    //************************ */
    // VIEW / PURE FUNCTIONS
    //************************ */

    // Getters

    function getUserSubsBalance(address _user) external view returns (uint256) {
        return s_userToSubsBalance[_user];
    }

    function getLinkTokenInterface() public view returns (address) {
        return address(i_LINK_TOKEN);
    }

    function getVrfSubsId() public view returns (uint64) {
        return i_vrfSubsId;
    }

    function getFuncsSubsId() public view returns (uint64) {
        return i_funcsSubsId;
    }
}
