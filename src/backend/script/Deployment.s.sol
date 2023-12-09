// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {PromptFightersNFT} from "../contracts/nft-contracts/eth-PromptFightersNft.sol";
import {FightersBarracks} from "../contracts/nft-contracts/avl-FightersBarracks.sol";
import {DeployFightsContracts} from "./deployment-processes/DeploymentBase.s.sol";

import {LinkTokenInterface} from "@chainlink/shared/interfaces/LinkTokenInterface.sol";
import {FightMatchmaker} from "../contracts/fight-contracts/FightMatchmaker.sol";

import {IAutomationRegistrar} from "../contracts/interfaces/IAutomation.sol";
import {IAutomationRegistry} from "../contracts/interfaces/IAutomation.sol";
import {ILogAutomation} from "@chainlink/automation/interfaces/ILogAutomation.sol";
import {Log} from "@chainlink/automation/interfaces/ILogAutomation.sol";
import {IAutomationForwarder} from "@chainlink/automation/interfaces/IAutomationForwarder.sol";

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
            console.log("+++++++++++++++++++++++++++++++++++++++");
            console.log("PromptFighters deployed at:");
            console.log(address(promptFighters));
            console.log("+++++++++++++++++++++++++++++++++++++++");

            // Intialize FightMatchmaker as it required frist the collection address.
            // @notice if we deploy the collection with CREATE2 this can be moved to DeploymentBase.s.sol
            address[] memory referencedContracts = new address[](3);
            referencedContracts[0] = address(fightExecutor);
            referencedContracts[1] = address(betsVault);
            referencedContracts[2] = address(promptFighters);
            // referencedContracts[2] = DEPLOYED_SEPOLIA_COLLECTION;

            // Fund automation registration with LINK
            console.log("Initializing matchmaker...");
            link_token.transfer(address(fightMatchmaker), LINK_AMOUNT_FOR_REGISTRATION);
            console.log(automationRegistration.triggerType);
            fightMatchmaker.initializeReferencesAndAutomation(
                referencedContracts, automationRegistry, automationRegistrar, automationRegistration
            );
            console.log("Done.");

            console.log("++++++++++++++++++++++++++++++++++++++++++");
            console.log("Check Functions subscription here:");
            string memory s = "https://functions.chain.link/sepolia/";
            console.log(string(abi.encodePacked(s, intToString(ETH_SEPOLIA_FUNCS_SUBS_ID))));
            console.log("++++++++++++++++++++++++++++++++++++++++++");
        }

        // Fuji
        if (block.chainid == AVL_FUJI_CHAIN_ID) {
            console.log("We are in FUJI");
            // Deploys all contracts that are shared accross chans.
            super.run();

            // Deploy barracks
            FightersBarracks barracks =
                new FightersBarracks(AVL_FUJI_CCIP_ROUTER, DEPLOYED_SEPOLIA_COLLECTION, fightMatchmaker);
            console.log("+++++++++++++++++++++++++++++++++++++++");
            console.log("+++++++++++++++++++++++++++++++++++++++");
            console.log("Avl barracks deployed at:");
            console.log(address(barracks));
            console.log("+++++++++++++++++++++++++++++++++++++++");

            // Initialize barracks
            console.log("Initializing CCIP on barrracks...");
            address[] memory referencedContracts = new address[](3);
            referencedContracts[0] = DEPLOYED_SEPOLIA_COLLECTION;
            barracks.initializeReferences(referencedContracts);
            console.log("Done.");

            // Intialize FightMatchmaker as it required frist the barracks address.
            // @notice if we deploy the collection with CREATE2 this can be moved to DeploymentBase.s.sol
            referencedContracts[0] = address(fightExecutor);
            referencedContracts[1] = address(betsVault);
            referencedContracts[2] = address(barracks);
            // referencedContracts[2] = DEPLOYED_FUJI_BARRACKS;
            // TODO: registering automation in Fuji not working, revert message says its a direct EVM error
            // in Chainlinks Register Logic B2_1 contract
            // Fund automation registration with LINK
            link_token.transfer(address(fightMatchmaker), LINK_AMOUNT_FOR_REGISTRATION);
            console.log("Initializing matchmaker...");
            fightMatchmaker.initializeReferencesAndAutomation(
                referencedContracts, automationRegistry, automationRegistrar, automationRegistration
            );
            console.log("Done.");

            console.log("++++++++++++++++++++++++++++++++++++++++++");
            console.log("Check Functions subscription here:");
            string memory s = "https://functions.chain.link/fuji/";
            console.log(string(abi.encodePacked(s, intToString(AVL_FUJI_FUNCS_SUBS_ID))));
            console.log("++++++++++++++++++++++++++++++++++++++++++");

            // TODO: add log for upkeepId and contracts addresses on block explorers
        }

        // NOTE: not tested, scripts not adapted for this chain
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

            // // Intialize FightMatchmaker as it required frist the barracks address.
            // // @notice if we deploy the collection with CREATE2 this can be moved to DeploymentBase.s.sol
            // referencedContracts[0] = address(fightExecutor);
            // referencedContracts[1] = address(betsVault);
            // referencedContracts[2] = address(barracks);
            // // TODO: registering automation in Mumbai not working, provides no reason
            // // Fund automation registration with LINK
            // link_token.transfer(address(fightMatchmaker), LINK_AMOUNT_FOR_REGISTRATION);
            // fightMatchmaker.initializeReferencesAndAutomation(
            //     referencedContracts, automationRegistry, automationRegistrar, automationRegistration
            // );
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
            console.log("Done.");
            vm.stopBroadcast();
        } else {
            revert("MUST BE SEPOLIA");
        }
    }

    // note: THE FOLLOWING CODE IS FOR TESTING ONLY
    // function trans() public {
    //     vm.startBroadcast();
    //     PromptFightersNFT collectionContract = PromptFightersNFT(DEPLOYED_SEPOLIA_COLLECTION);
    //     collectionContract.transferFrom(msg.sender, PLAYER_FOR_FIGHTS, 2);
    //     vm.stopBroadcast();
    // }

    // NOTE: said auto-approved disabled
    /*
    function initSepoliaMatchmaker() public {
        if (block.chainid == ETH_SEPOLIA_CHAIN_ID) {
            // Initialize collection contract.
            vm.startBroadcast();
            // // Intialize FightMatchmaker as it required frist the collection address.
            // // @notice if we deploy the collection with CREATE2 this can be moved to DeploymentBase.s.sol
            address[] memory referencedContracts = new address[](3);
            referencedContracts[0] = SEPOLIA_FIGHT_EXECUTOR;
            referencedContracts[1] = SEPOLIA_BETS_OFFICIAL;
            referencedContracts[2] = DEPLOYED_SEPOLIA_COLLECTION;
            // Fund automation registration with LINK
            LinkTokenInterface(ETH_SEPOLIA_LINK).transfer(SEPOLIA_FIGHT_MATCHMAKER, LINK_AMOUNT_FOR_REGISTRATION);
            FightMatchmaker(SEPOLIA_FIGHT_MATCHMAKER).initializeReferencesAndAutomation(
                referencedContracts,
                automationRegistry,
                automationRegistrar,
                automationRegistration,
                ETH_SEPOLIA_UPKEEP_ID
            );
            vm.stopBroadcast();
        } else {
            revert("MUST BE SEPOLIA");
        }*/

    // function initFujiMatchmaker() public {
    //     // NOTE: code to register automation
    //     address[] memory referencedContracts = new address[](3);

    //     referencedContracts[0] = FUJI_FIGHT_EXECUTOR;
    //     // referencedContracts[1] = FUJI_BETS_VAULT;//NOTE: needed if testing, delete after
    //     referencedContracts[2] = DEPLOYED_FUJI_BARRACKS;

    //     // IAutomationRegistry automationRegistry  ; //= IAutomationRegistry(AVL_FUJI_REGISTRY);
    //     // IAutomationRegistrar automationRegistrar; //= IAutomationRegistrar(AVL_FUJI_REGISTRAR);
    //     // uint256 automationBalanceThreshold = FUJI_AUTOMATION_THRESHOLD_BALANCE;
    //     // IAutomationRegistrar.RegistrationParams memory automationRegistration;
    //     //  = IAutomationRegistrar.RegistrationParams({
    //     // name: "Fuji Automation PromptFighters",
    //     // encryptedEmail: new bytes(0),
    //     // upkeepContract: address(0), // Set at construction time address(this)
    //     // gasLimit: GAS_LIMIT_FUJI_AUTOMATION,
    //     // adminAddress: address(0), // Set at construction time address(this)
    //     // triggerType: 1,
    //     // checkData: new bytes(0),
    //     // triggerConfig: new bytes(0), // Set at construction time, requires address(this)
    //     // offchainConfig: new bytes(0),
    //     // amount: LINK_AMOUNT_FOR_REGISTRATION
    //     // });

    //     vm.startBroadcast();
    //     // Fund automation registration with LINK
    //     LinkTokenInterface(AVL_FUJI_LINK).transfer(FUJI_FIGHT_MATCHMAKER, LINK_AMOUNT_FOR_REGISTRATION);
    //     FightMatchmaker(FUJI_FIGHT_MATCHMAKER).initializeReferencesAndAutomation(
    //         referencedContracts, automationRegistry, automationRegistrar, automationRegistration
    //     );
    //     vm.stopBroadcast();
    // }
}
