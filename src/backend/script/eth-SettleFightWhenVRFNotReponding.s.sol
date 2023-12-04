// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {FightMatchmaker} from "../contracts/fight-contracts/FightMatchmaker.sol";
import {IFightMatchmaker} from "../contracts/interfaces/IFightMatchmaker.sol";

import "../contracts/Utils.sol";

import {Script, console2} from "forge-std/Script.sol";
import "forge-std/console.sol";

/**
 * @dev Settles a fight which:
 * Challenger: DEPLOYER
 * Nft Challenger: 1
 * Chanllengee: DEPLOYER
 * Challengee Nft: 2
 */
contract AutomatedFight is Script {
    FightMatchmaker public matchmaker;

    // TODO: delete when finish tensting, add them to Utils.sol
    address constant mtch = 0x464526fb0634c10B749DB17d735bB189f7FEFa2a;

    function setUp() public virtual {
        // TODO: get matchmaker address add
        matchmaker = FightMatchmaker(mtch);
    }

    function run() public virtual {
        vm.startBroadcast();

        if (block.chainid == ETH_SEPOLIA_CHAIN_ID) {
            bytes32 fightId = matchmaker.getFightId(DEPLOYER, 1, DEPLOYER, 2);
            console.log("Trying to request fight...");
            matchmaker.settleFight(fightId, IFightMatchmaker.WinningAction.REQUESTER_WIN);
        }

        vm.stopBroadcast();
    }
}
