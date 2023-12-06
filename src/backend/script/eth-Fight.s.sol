// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {CcipNftBridge} from "../contracts/CcipNftBridge.sol";
import {FightMatchmaker} from "../contracts/fight-contracts/FightMatchmaker.sol";
import {FightExecutor} from "../contracts/fight-contracts/FightExecutor.sol";

import {LinkTokenInterface} from "@chainlink/shared/interfaces/LinkTokenInterface.sol";

import "../contracts/Utils.sol";

import {Script, console2} from "forge-std/Script.sol";
import "forge-std/console.sol";

/**
 * @dev Executes a fight on Sepolia or Fuji.
 *
 * Call requestF() to request the fight.
 * Call acceptF() to accept the fight.
 * The fight is defined in the Utils.sol file.
 */
contract Fight is Script {
    CcipNftBridge public collectionContract;
    FightMatchmaker public matchmaker;
    FightExecutor public executor;

    LinkTokenInterface public linkToken;

    FightToExecuteInScripts public fightToExecute = new FightToExecuteInScripts();
    IFightMatchmaker.FightRequest public fr = fightToExecute.getFReq();

    string public CHAIN_ON_NAME;
    string public CHAIN_ON_SUBID_FUNCTIONS;
    string public CHAIN_ON_SUBID_VRF;

    function setUp() public {
        if (block.chainid == ETH_SEPOLIA_CHAIN_ID) {
            collectionContract = CcipNftBridge(DEPLOYED_SEPOLIA_COLLECTION);
            matchmaker = FightMatchmaker(SEPOLIA_FIGHT_MATCHMAKER);
            linkToken = LinkTokenInterface(ETH_SEPOLIA_LINK);
            executor = FightExecutor(SEPOLIA_FIGHT_EXECUTOR);
            CHAIN_ON_NAME = "sepolia";
            CHAIN_ON_SUBID_FUNCTIONS = intToString(ETH_SEPOLIA_FUNCS_SUBS_ID);
            CHAIN_ON_SUBID_VRF = intToString(executor.getVrfSubsId());
        }

        if (block.chainid == AVL_FUJI_CHAIN_ID) {
            collectionContract = CcipNftBridge(DEPLOYED_FUJI_BARRACKS);
            matchmaker = FightMatchmaker(FUJI_FIGHT_MATCHMAKER);
            linkToken = LinkTokenInterface(AVL_FUJI_LINK);
            executor = FightExecutor(FUJI_FIGHT_EXECUTOR);
            CHAIN_ON_NAME = "fuji";
            CHAIN_ON_SUBID_FUNCTIONS = intToString(AVL_FUJI_FUNCS_SUBS_ID);
            CHAIN_ON_SUBID_VRF = intToString(executor.getVrfSubsId());
        }
    }

    function run() public {}

    function requestF() public {
        vm.startBroadcast();

        // Fund Chainlink Subscriptions: Functions and VRF
        console.log("Funding LINK consumption of executor contract...");
        uint256 funds = 12 ether;
        linkToken.approve(address(executor), funds);
        executor.fundMySubscription(funds);
        console.log("Funded.");

        console.log(msg.sender);
        console.log(fr.challengerNftId);
        console.log(fr.minBet);
        console.log(fr.acceptanceDeadline);
        console.log(fr.challengee);
        console.log(fr.challengeeNftId);

        console.log("Trying to request fight...");
        matchmaker.requestFight{value: 0.005 ether}(fr);
        console.log("Fight Requested.");
        console.log("FightID:");
        console.logBytes32(fightToExecute.s_fighReqFightID());

        vm.stopBroadcast();
    }

    function acceptF() public {
        vm.startBroadcast();

        bytes32 fightId = fightToExecute.s_fighReqFightID();
        console.log("Trying to accept fight...");
        matchmaker.acceptFight{value: 0.005 ether}(fightId, fightToExecute.ACCEPTOR_NFT_ID());
        console.log("Fight accepted. Wait till Functions and VRF are executed.");
        console.log("++++++++++++++++++++++++++++++++++++++++++");
        console.log("Check Functions request status at:");
        console.log("https://functions.chain.link/", CHAIN_ON_NAME, "/", CHAIN_ON_SUBID_FUNCTIONS);
        console.log("++++++++++++++++++++++++++++++++++++++++++");
        console.log("Check VRF request status at:");
        console.log("https://vrf.chain.link/", CHAIN_ON_NAME, "/", CHAIN_ON_SUBID_VRF);
        console.log("++++++++++++++++++++++++++++++++++++++++++");

        vm.stopBroadcast();
    }

    // TODO: delete when finish tensting
    function change() public {
        vm.startBroadcast();

        address add = SEPOLIA_FIGHT_MATCHMAKER;
        collectionContract.setMatchmaker(add);

        vm.stopBroadcast();
    }
}
