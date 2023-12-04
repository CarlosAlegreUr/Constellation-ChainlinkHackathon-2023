// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {PromptFightersNFT} from "../contracts/nft-contracts/eth-PromptFightersNft.sol";
import {FightersBarracks} from "../contracts/nft-contracts/avl-FightersBarracks.sol";
import {DeployFightsContracts} from "./deployment-processes/DeploymentBase.s.sol";

import "../contracts/Utils.sol";
import "forge-std/console.sol";

/**
 * @title PromptFightersDeploy
 * @author @CarlosAlegreUr
 * @notice Deploys all contracts needed for the PromptFighters system.
 * As complete initailization of the system is not possible in one transaction
 * due to the multi-chain nature of the system, you will need to run after
 * deploying the Barracks on the other chain to run the initSepoliaCollection() function
 * on ths script.
 */
contract PromptFightersDeploy is DeployFightsContracts {
    function setUp() public override {
        super.setUp();
    }

    function run() public override {
        vm.startBroadcast();

        // Sepolia
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

            // Intialize FightMatchmaker as it required frist the collection address.
            // @notice if we deploy the collection with CREATE2 this can be moved to DeploymentBase.s.sol
            address[] memory referencedContracts = new address[](3);
            referencedContracts[0] = address(fightExecutor);
            referencedContracts[1] = address(betsVault);
            referencedContracts[2] = address(address(promptFighters));
            // Fund automation registration with LINK
            link_token.transfer(address(fightMatchmaker), LINK_AMOUNT_FOR_REGISTRATION);
            fightMatchmaker.initializeReferencesAndAutomation(
                referencedContracts, automationRegistry, automationRegistrar, automationRegistration
            );
        }

        // Fuji
        if (block.chainid == AVL_FUJI_CHAIN_ID) {
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
            address[] memory referencedContracts = new address[](3);
            referencedContracts[0] = DEPLOYED_SEPOLIA_COLLECTION;
            barracks.initializeReferences(referencedContracts);

            // Intialize FightMatchmaker as it required frist the barracks address.
            // @notice if we deploy the collection with CREATE2 this can be moved to DeploymentBase.s.sol
            referencedContracts[0] = address(fightExecutor);
            referencedContracts[1] = address(betsVault);
            referencedContracts[2] = address(barracks);
            // TODO: registering automation in Fuji not working, revert message says its a direct EVM error
            // in Chainlinks Register Logic B2_1 contract

            // Fund automation registration with LINK
            link_token.transfer(address(fightMatchmaker), LINK_AMOUNT_FOR_REGISTRATION);
            fightMatchmaker.initializeReferencesAndAutomation(
                referencedContracts, automationRegistry, automationRegistrar, automationRegistration
            );
        }

        if (block.chainid == PLY_MUMBAI_CHAIN_ID) {
            console.log("We are in MUMBAI");
            // Deploys all contracts that are shared accross chans.
            super.run();

            // Deploy barracks
            FightersBarracks barracks =
                new FightersBarracks(PLY_MUMBAI_CCIP_ROUTER, DEPLOYED_SEPOLIA_COLLECTION, fightMatchmaker);
            console.log("COPY THE FOLLOWING ADDRESS IN THE Utils.sol:");
            console.log("Avl barracks deployed at:");
            console.log(address(barracks));

            // Initialize barracks
            console.log("Initializing CCIP on barrracks...");
            address[] memory referencedContracts = new address[](3);
            referencedContracts[0] = DEPLOYED_SEPOLIA_COLLECTION;
            barracks.initializeReferences(referencedContracts);

            // Intialize FightMatchmaker as it required frist the barracks address.
            // @notice if we deploy the collection with CREATE2 this can be moved to DeploymentBase.s.sol
            referencedContracts[0] = address(fightExecutor);
            referencedContracts[1] = address(betsVault);
            referencedContracts[2] = address(barracks);
            // TODO: registering automation in Mumbai not working, provides no reason
            // Fund automation registration with LINK
            link_token.transfer(address(fightMatchmaker), LINK_AMOUNT_FOR_REGISTRATION);
            fightMatchmaker.initializeReferencesAndAutomation(
                referencedContracts, automationRegistry, automationRegistrar, automationRegistration
            );
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
