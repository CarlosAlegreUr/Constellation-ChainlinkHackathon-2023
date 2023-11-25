// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {FightersBarracks} from "../src/nft-contracts/avl-FightersBarracks.sol";

import {DeployFightsContracts} from "./Deployment.s.sol";

import "../src/Utils.sol";

import {Script, console2} from "forge-std/Script.sol";
import "forge-std/console.sol";

contract BarracksAvlDeploy is DeployFightsContracts {
    // TODO: Write after ETH deployed.
    address ETH_COLLECTION_ADDRESS = address(888);

    function setUp() public override {
        super.run();
        funcs_router = AVL_FUJI_FUNCTIONS_ROUTER;
        vrf_router = AVL_FUJI_VRF_COORDINATOR;
        // TODO: Automation Contracts for Matchmaker add

        // Deploys all contracts that are shared accross chans.
        DeployFightsContracts.run();
    }

    function run() public override {
        vm.broadcast();
        // Deploy collection
        FightersBarracks barracks =
            new FightersBarracks(ETH_SEPOLIA_CCIP_ROUTER, ETH_COLLECTION_ADDRESS, fightMatchmaker);
        console.log("Avl barracks deployed at:");
        console.log(address(barracks));
        vm.stopBroadcast();
    }
}
