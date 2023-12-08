// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {PromptFightersNFT} from "../contracts/nft-contracts/eth-PromptFightersNft.sol";
import {FightMatchmaker} from "../contracts/fight-contracts/FightMatchmaker.sol";
import {IFightMatchmaker} from "../contracts/interfaces/IFightMatchmaker.sol";
import {FightExecutor} from "../contracts/fight-contracts/FightExecutor.sol";

import "../contracts/Utils.sol";

import {Script, console2} from "forge-std/Script.sol";
import "forge-std/console.sol";

import {LinkTokenInterface} from "@chainlink/shared/interfaces/LinkTokenInterface.sol";
import {IAutomationRegistrar} from "../contracts/interfaces/IAutomation.sol";

/**
 * @dev Sets NFt 2 to be automated and requests a fight with NFT 1
 * This script is meant to be run on the Sepolia testnet
 * It will fund the matchmaker and executor contracts with LINK
 * and then request a fight wth NFT 1 expecting to be automatically
 * accepted by the upkeep in the matchmaker contract with NFT 2.
 */
contract AutomatedFight is Script {
    PromptFightersNFT public collectionContract;
    FightMatchmaker public matchmaker;
    FightExecutor public executor;
    LinkTokenInterface public linkToken;
    uint256 public AUTOMATION_BALANCE_THRESHOLD;
    FightToExecuteInScripts public fightToExecute = new FightToExecuteInScripts();
    IFightMatchmaker.FightRequest public fr = fightToExecute.getFReq();

    uint256 public NFT_TO_AUTOMATE = 2;

    function setUp() public {
        if (block.chainid == ETH_SEPOLIA_CHAIN_ID) {
            collectionContract = PromptFightersNFT(DEPLOYED_SEPOLIA_COLLECTION);
            matchmaker = FightMatchmaker(SEPOLIA_FIGHT_MATCHMAKER);
            executor = FightExecutor(SEPOLIA_FIGHT_EXECUTOR);
            linkToken = LinkTokenInterface(ETH_SEPOLIA_LINK);
            AUTOMATION_BALANCE_THRESHOLD = LINK_SEPOLIA_AUTOMATION_THRESHOLD_BALANCE;
        }
    }

    function run() public {
        vm.startBroadcast();

        // Fund LINK for automation upkeeps
        console.log("Funding LINK services for fight contracts...");
        // Fund Chainlink Automation in matchcmaker
        linkToken.approve(address(matchmaker), AUTOMATION_BALANCE_THRESHOLD);

        // Set NFT 2 to be automated
        uint256 ethToSend = MIN_ETH_BET * 3;
        matchmaker.setNftAutomated{value: ethToSend}(
            NFT_TO_AUTOMATE, 0.001 ether, 0.001 ether, uint96(AUTOMATION_BALANCE_THRESHOLD)
        );

        console.log("NFT 2 is now automated...");
        console.log("Fight should be accepted by upkeep in later block after detecting a request...");
        console.log("Check state on block explorer...");

        vm.stopBroadcast();
    }

    function request() public {
        vm.startBroadcast();
        // TESTING ONLY
        // console.log("Funding LINK consumption of executor contract...");
        // uint256 funds = 2.5 ether; //12 ether;
        // linkToken.approve(address(executor), funds);
        // executor.fundMySubscription(funds);
        // console.log("Funded.");

        console.log("Trying to request fight...");
        matchmaker.requestFight{value: 0.005 ether}(fr);
        console.log("DONE");
        vm.stopBroadcast();
    }

    function initializeUpkeep() public {
        vm.startBroadcast();
        console.log("Trying to initialize upkeep...");
        matchmaker.setUpkeepId(ETH_SEPOLIA_UPKEEP_ID);
        console.log("DONE");
        vm.stopBroadcast();
    }

    // TEST ONLY
    // function regiterAutomation() public {
    //     vm.startBroadcast();
    //     // Automation registration complete params that require address(this)
    //     IAutomationRegistrar _registrar = IAutomationRegistrar(ETH_SEPOLIA_REGISTRAR);
    //     IAutomationRegistrar.RegistrationParams memory _params;
    //     _params.name = "Sepolia Automation PromptFighters";
    //     _params.encryptedEmail = new bytes(0);
    //     _params.gasLimit = GAS_LIMIT_SEPOLIA_AUTOMATION;
    //     _params.triggerType = 1;
    //     _params.checkData = new bytes(0);
    //     _params.offchainConfig = new bytes(0);
    //     _params.amount = 5 ether; //LINK_AMOUNT_FOR_REGISTRATION;
    //     _params.upkeepContract = SEPOLIA_FIGHT_MATCHMAKER;
    //     _params.adminAddress = msg.sender;
    //     _params.triggerConfig = abi.encode(
    //         SEPOLIA_FIGHT_MATCHMAKER, // Listen to this contract
    //         2, // Binary 010, considering only topic2 (fightId)
    //         keccak256("FightMatchmaker__FightRequested(address,uint256,bytes32,uint256,uint256)"), // Listen for this event
    //         0x0, // If you don't want to filter on a specific nftId
    //         0x0, // If you don't want to filter on a specific fightId
    //         0x0 // If you don't want to filter on a specific bet
    //     );
    //     LinkTokenInterface(ETH_SEPOLIA_LINK).approve(address(_registrar), _params.amount);
    //     uint256 upkeepID = _registrar.registerUpkeep(_params);
    //     console.log(upkeepID);
    //     vm.stopBroadcast();
    // }
}
