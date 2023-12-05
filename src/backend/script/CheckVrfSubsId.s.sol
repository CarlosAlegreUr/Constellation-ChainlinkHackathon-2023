// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {FightExecutor} from "../contracts/fight-contracts/FightExecutor.sol";

import "../contracts/Utils.sol";

import {Script, console2} from "forge-std/Script.sol";
import "forge-std/console.sol";

/**
 * @dev Displays on screen the VRF subs Id.
 */
contract CheckVrfSubsId is Script {
    FightExecutor public executor;

    function setUp() public virtual {
        executor = FightExecutor(SEPOLIA_FIGHT_EXECUTOR_OFFICIAL);
    }

    function run() public virtual {
        vm.startBroadcast();

        uint64 vrfSubsId = executor.getVrfSubsId();
        console.log("+++++++++++++++++++++++");
        console.log("+++++++++++++++++++++++");
        console.log("Current VRF subs ID is:");
        console.log(vrfSubsId);
        console.log("+++++++++++++++++++++++");
        console.log("+++++++++++++++++++++++");

        vm.stopBroadcast();
    }
}
