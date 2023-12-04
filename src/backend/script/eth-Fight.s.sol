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
 * @dev Executes a fight agains yourself in Sepolia. You must have minted 2 NFTS.
 * Nft id 1 and 2 must be yours.
 */
contract Fight is Script {
    PromptFightersNFT public collectionContract;
    FightMatchmaker public matchmaker;
    FightExecutor public executor;
    LinkTokenInterface public linkToken = LinkTokenInterface(ETH_SEPOLIA_LINK);
    IFightMatchmaker.FightRequest fr;

    uint256 public CHALLENGER_NFT_ID = 1;
    uint256 public CHALLENGEE_NFT_ID = 2;

    function setUp() public virtual {
        collectionContract = PromptFightersNFT(DEPLOYED_SEPOLIA_COLLECTION);
        matchmaker = FightMatchmaker(SEPOLIA_FIGHT_MATCHMAKER_OFFICIAL);
        executor = FightExecutor(SEPOLIA_FIGHT_EXECUTOR_OFFICIAL);

        fr = IFightMatchmaker.FightRequest({
            challengerNftId: CHALLENGER_NFT_ID,
            minBet: 0.001 ether,
            acceptanceDeadline: block.timestamp + 1 days,
            challengee: PLAYER_FOR_FIGHTS,
            challengeeNftId: CHALLENGEE_NFT_ID
        });
    }

    function run() public virtual {
        vm.startBroadcast();

        if (block.chainid == ETH_SEPOLIA_CHAIN_ID) {
            // Send NFT2 to player so he can accept fight
            console.log("Sending NFTid 2 to player so he can fight...");
            collectionContract.transferFrom(DEPLOYER, PLAYER_FOR_FIGHTS, CHALLENGEE_NFT_ID);

            // Fund Chainlink Subscriptions
            console.log("Funding LINK consumption from fight contracts...");
            linkToken.approve(address(executor), 1 ether);
            executor.fundMySubscription(1 ether);

            console.log("Trying to request fight...");
            matchmaker.requestFight{value: 0.005 ether}(fr);
        }

        vm.stopBroadcast();
    }

    function accept() public {
        vm.startBroadcast();

        bytes32 fightId = matchmaker.getFightId(DEPLOYER, fr.challengerNftId, fr.challengee, fr.challengeeNftId);
        console.log("Trying to accept fight...");
        matchmaker.acceptFight{value: 0.005 ether}(fightId, CHALLENGEE_NFT_ID);

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
    function settle() public {
        vm.startBroadcast();
        matchmaker.settleFight(
            0xeefa5ba8b831d9208f3fdbe74caa31a6fd8dddf340aed5e97a8c6bea81237cc1,
            IFightMatchmaker.WinningAction.REQUESTER_WIN
        );
        vm.stopBroadcast();
    }
}
