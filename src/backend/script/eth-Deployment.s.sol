// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {PromptFightersNFT} from "../src/nft-contracts/eth-PromptFightersNft.sol";

import {DeployFightsContracts} from "./Deployment.s.sol";

import "../src/Utils.sol";

import "forge-std/console.sol";

contract PromptFightersDeploy is DeployFightsContracts {
    function setUp() public override {
        funcs_router = ETH_SEPOLIA_FUNCTIONS_ROUTER;
        funcs_subsId = ETH_SEPOLIA_FUNCS_SUBS_ID;
        vrf_router = ETH_SEPOLIA_VRF_COORDINATOR;
        // TODO: Automation Contracts for Matchmaker add

        // Deploys all contracts that are shared accross chans.
        super.run();
    }

    function run() public override {
        vm.startBroadcast();
        // Deploy collection
        PromptFightersNFT promptFighters =
            new PromptFightersNFT(ETH_SEPOLIA_FUNCTIONS_ROUTER, funcs_subsId, ETH_SEPOLIA_CCIP_ROUTER, fightMatchmaker);
        console.log("PromptFighters deployed at:");
        console.log(address(promptFighters));
        vm.stopBroadcast();
    }
}
