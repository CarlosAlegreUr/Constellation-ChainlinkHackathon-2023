// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {PromptFightersNFT} from "../src/nft-contracts/eth-PromptFightersNft.sol";

import {DeployFightsContracts} from "./Deployment.s.sol";

import "../src/Utils.sol";

import "forge-std/console.sol";

contract PromptFightersDeploy is DeployFightsContracts {
    function setUp() public override {
        super.run();
        funcs_router = ETH_SEPOLIA_FUNCTIONS_ROUTER;
        vrf_router = ETH_SEPOLIA_VRF_COORDINATOR;
        // TODO: Automation Contracts for Matchmaker add

        // Deploys all contracts that are shared accross chans.
        DeployFightsContracts.run();
    }

    function run() public override {
        vm.broadcast();
        // Deploy collection
        PromptFightersNFT promptFighters =
            new PromptFightersNFT(ETH_SEPOLIA_FUNCTIONS_ROUTER, ETH_SEPOLIA_CCIP_ROUTER, fightMatchmaker);
        console.log("PromptFighters deployed at:");
        console.log(address(promptFighters));
        vm.stopBroadcast();
    }
}
