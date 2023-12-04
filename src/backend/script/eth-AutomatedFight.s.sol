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
    address constant mtch = 0x464526fb0634c10B749DB17d735bB189f7FEFa2a;
    address constant exec = 0x74CB670f9E92bDA0371848c2a8f52b248053C9c3;

    function setUp() public virtual {
        collectionContract = PromptFightersNFT(DEPLOYED_SEPOLIA_COLLECTION);
        // TODO: get matchmaker address add
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
            matchmaker.setNftAutomated(2, 0.001 ether, 0.001 ether, automationFunds);

            IFightMatchmaker.FightRequest memory fr = IFightMatchmaker.FightRequest({
                challengerNftId: 1,
                minBet: 0.001 ether,
                acceptanceDeadline: block.timestamp + 1 days,
                challengee: DEPLOYER,
                challengeeNftId: 2
            });
            console.log("Trying to request fight...");
            matchmaker.requestFight{value: 0.005 ether}(fr);

            console.log("Fight should be accepted by upkeep in later block...");
            console.log("Check state on block explorer...");
        }

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
