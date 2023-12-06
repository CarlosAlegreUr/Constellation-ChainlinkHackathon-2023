// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {FightMatchmaker} from "../contracts/fight-contracts/FightMatchmaker.sol";
import {IFightMatchmaker} from "../contracts/interfaces/IFightMatchmaker.sol";

import "../contracts/Utils.sol";

import {Script, console2} from "forge-std/Script.sol";
import "forge-std/console.sol";

/**
 * @dev Settles a fight in Sepolia as so far VRF request
 * remain in pending state forever.
 *
 * @notice Makess REQUESTER win the fight.
 *
 * Interestingly enough, in Fuji VRF requests actually work.
 */
contract SettleFightWhenVRFNotReponding is Script {
    FightMatchmaker public matchmaker = FightMatchmaker(SEPOLIA_FIGHT_MATCHMAKER);
    FightToExecuteInScripts public fightToExecute = new FightToExecuteInScripts();
    IFightMatchmaker.WinningAction public winner = IFightMatchmaker.WinningAction.REQUESTER_WIN;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        if (block.chainid == ETH_SEPOLIA_CHAIN_ID) {
            bytes32 fightId = fightToExecute.s_fighReqFightID();
            console.log("Trying to settle fight...");
            matchmaker.settleFight(fightId, winner);
            console.log("Fight settled...");
            console.log("Fight ID: ");
            console.logBytes32(fightId);
        } else {
            console.log("This script is only for Sepolia");
        }

        vm.stopBroadcast();
    }
}
