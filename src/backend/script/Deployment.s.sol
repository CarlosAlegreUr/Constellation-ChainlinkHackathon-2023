// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {PromptFightersNFT} from "../contracts/nft-contracts/eth-PromptFightersNft.sol";
import {FightersBarracks} from "../contracts/nft-contracts/avl-FightersBarracks.sol";
import {DeployFightsContracts} from "./DeploymentBase.s.sol";

import "../contracts/Utils.sol";

import "forge-std/console.sol";

contract PromptFightersDeploy is DeployFightsContracts {
    function setUp() public override {
        // TODO: Automation Contracts for Matchmaker add
        if (block.chainid == ETH_SEPOLIA_CHAIN_ID) {
            funcs_router = ETH_SEPOLIA_FUNCTIONS_ROUTER;
            funcs_subsId = ETH_SEPOLIA_FUNCS_SUBS_ID;
            vrf_router = ETH_SEPOLIA_VRF_COORDINATOR;
            link_token = ETH_SEPOLIA_LINK;
        }

        if (block.chainid == AVL_FUJI_CHAIN_ID) {
            funcs_router = AVL_FUJI_FUNCTIONS_ROUTER;
            funcs_subsId = AVL_FUJI_FUNCS_SUBS_ID;
            vrf_router = AVL_FUJI_VRF_COORDINATOR;
            link_token = AVL_FUJI_LINK;
        }
    }

    function run() public override {
        vm.startBroadcast();
        if (block.chainid == ETH_SEPOLIA_CHAIN_ID) {
            console.log("We are in SEPOLIA");
            // Deploys all contracts that are shared accross chans.
            super.run();

            // Deploy collection
            console.log("Deploying collection...");
            PromptFightersNFT promptFighters = new PromptFightersNFT(
                ETH_SEPOLIA_FUNCTIONS_ROUTER, funcs_subsId, ETH_SEPOLIA_CCIP_ROUTER, fightMatchmaker
            );
            console.log("PromptFighters deployed at:");
            console.log(address(promptFighters));
        } else {
            console.log("We are in FUJI");
            // Deploys all contracts that are shared accross chans.
            super.run();

            // Deploy barracks
            FightersBarracks barracks =
                new FightersBarracks(AVL_FUJI_CCIP_ROUTER, DEPLOYED_SEPOLIA_COLLECTION, fightMatchmaker);
            console.log("COPY THE FOLLOWING ADDRESS IN THE Utils.sol:");
            console.log("Avl barracks deployed at:");
            console.log(address(barracks));

            // Initialize barracks
            console.log("Initializing CCIP on barrracks...");
            address[] memory referencedContracts = new address[](1);
            referencedContracts[0] = DEPLOYED_SEPOLIA_COLLECTION;
            barracks.initializeReferences(referencedContracts);
        }
        vm.stopBroadcast();
    }

    function initSepoliaCollection() public {
        if (block.chainid == ETH_SEPOLIA_CHAIN_ID) {
            // Initialize collection contract.
            vm.startBroadcast();
            console.log("Initializing CCIP on collection...");
            PromptFightersNFT collectionContract = PromptFightersNFT(DEPLOYED_SEPOLIA_COLLECTION);
            address[] memory referencedContracts = new address[](1);
            referencedContracts[0] = DEPLOYED_FUJI_BARRACKS;
            collectionContract.initializeReferences(referencedContracts);
            vm.stopBroadcast();
        } else {
            revert("MUST BE SEPOLIA");
        }
    }
}
