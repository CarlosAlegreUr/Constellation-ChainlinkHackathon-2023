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
    LinkTokenInterface public linkToken = LinkTokenInterface(ETH_SEPOLIA_LINK);

    // TODO: delete when finish tensting, add them to Utils.sol
    address constant mtch = SEPOLIA_FIGHT_MATCHMAKER;
    address constant exec = SEPOLIA_FIGHT_EXECUTOR;

    function setUp() public virtual {
        collectionContract = PromptFightersNFT(DEPLOYED_SEPOLIA_COLLECTION);
        matchmaker = FightMatchmaker(mtch);
        executor = FightExecutor(exec);
    }

    function run() public virtual {
        vm.startBroadcast();

        if (block.chainid == ETH_SEPOLIA_CHAIN_ID) {
            // Automating NFT 2
            // Fund LINK for automation upkeeps
            console.log("Funding LINK services for fight contracts...");
            uint256 automationFunds = 3 ether;
            // Fund Chainlink Automation in matchcmaker
            linkToken.approve(address(matchmaker), automationFunds);
            // Fund Chainlink Subscriptions in executor
            linkToken.approve(address(executor), 1 ether);
            executor.fundMySubscription(1 ether);

            // Set NFT 2 to be automated
            matchmaker.setNftAutomated(2, 0.001 ether, 0.001 ether, automationFunds);

            console.log("NFT 2 is now automated...");
            console.log("Fight should be accepted by upkeep in later block after detecting a request...");
            console.log("Check state on block explorer...");
        }

        vm.stopBroadcast();
    }

    function trans() public {
        vm.startBroadcast();
        collectionContract.transferFrom(DEPLOYER, PLAYER_FOR_FIGHTS, 2);
        vm.stopBroadcast();
    }

    function request() public {
        vm.startBroadcast();
        IFightMatchmaker.FightRequest memory fr = IFightMatchmaker.FightRequest({
            challengerNftId: 3,
            minBet: 0.001 ether,
            acceptanceDeadline: block.timestamp + 1 days,
            challengee: PLAYER_FOR_FIGHTS,
            challengeeNftId: 2
        });

        console.log("Trying to request fight...");
        matchmaker.requestFight{value: 0.005 ether}(fr);
        vm.stopBroadcast();
    }

    function regiterAutomation() public {
        vm.startBroadcast();

        // Automation registration complete params that require address(this)
        IAutomationRegistrar _registrar = IAutomationRegistrar(ETH_SEPOLIA_REGISTRAR);
        IAutomationRegistrar.RegistrationParams memory _params;
        _params.name = "Sepolia Automation PromptFighters";
        _params.encryptedEmail = new bytes(0);
        _params.gasLimit = GAS_LIMIT_SEPOLIA_AUTOMATION;
        _params.triggerType = 1;
        _params.checkData = new bytes(0);
        _params.offchainConfig = new bytes(0);
        _params.amount = LINK_AMOUNT_FOR_REGISTRATION;
        _params.upkeepContract = SEPOLIA_FIGHT_MATCHMAKER;
        _params.adminAddress = msg.sender;
        _params.triggerConfig = abi.encode(
            SEPOLIA_FIGHT_MATCHMAKER, // Listen to this contract
            2, // Binary 010, considering only topic2 (fightId)
            keccak256("FightMatchmaker__FightRequested(address,uint256,bytes32,uint256,uint256)"), // Listen for this event
            0x0, // If you don't want to filter on a specific nftId
            0x0, // If you don't want to filter on a specific fightId
            0x0 // If you don't want to filter on a specific bet
        );
        LinkTokenInterface(ETH_SEPOLIA_LINK).approve(address(_registrar), _params.amount);
        uint256 upkeepID = _registrar.registerUpkeep(_params);
        console.log(upkeepID);
        vm.stopBroadcast();
    }

    function manualsetup() public {
        vm.startBroadcast();
        uint256 uid = 98785675887033837089720433517441719857293902855493994579632517239481229958059;
        address forwarder = 0xD497BDE78255a86632445d29B2A74d8f2a913aB9;
        FightMatchmaker(mtch).setForwarderDuh(forwarder);
        FightMatchmaker(mtch).setUpkeepId(uid);
        vm.stopBroadcast();
    }

    // TODO: delete when finish tensting
    // function change() public {
    //     vm.startBroadcast();

    //     address add = mtch;
    //     collectionContract.setMatchmaker(add);
    //     vm.stopBroadcast();
    // }

    // TODO: delete when finish tensting
    // function settle() public {
    //     vm.startBroadcast();
    //     FightMatchmaker m = FightMatchmaker(mtch);
    //     m.settleFight(
    //         0x5c5f8cdc3d63547e35825fe0c326cd2224f7dcbd7e0b734a6fffa131e4f98643,
    //         IFightMatchmaker.WinningAction.REQUESTER_WIN
    //     );
    //     vm.stopBroadcast();
    // }
}
