// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {PromptFightersNFT} from "../contracts/nft-contracts/eth-PromptFightersNft.sol";
import {FightMatchmaker} from "../contracts/fight-contracts/FightMatchmaker.sol";
import {IFightMatchmaker} from "../contracts/interfaces/IFightMatchmaker.sol";

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

    // TODO: delete when finish tensting
    // address constant mtch = 0x1FCA9dF2Ff9ba2bCB3fEdeE7c79ceE09c949E892;

    function setUp() public virtual {
        collectionContract = PromptFightersNFT(DEPLOYED_SEPOLIA_COLLECTION);
        // TODO: get matchmaker address add
        // matchmaker = FightMatchmaker(mtch);
    }

    function run() public virtual {
        vm.startBroadcast();

        if (block.chainid == ETH_SEPOLIA_CHAIN_ID) {
            IFightMatchmaker.FightRequest memory fr = IFightMatchmaker.FightRequest({
                challengerNftId: 1,
                minBet: 0.001 ether,
                acceptanceDeadline: block.timestamp + 1 days,
                challengee: DEPLOYER,
                challengeeNftId: 2
            });
            console.log("Trying to request fight...");
            matchmaker.requestFight{value: 0.005 ether}(fr);

            bytes32 fightId = matchmaker.getFightId(DEPLOYER, fr.challengerNftId, fr.challengee, fr.challengeeNftId);
            console.log("Trying to accept fight...");
            matchmaker.acceptFight{value: 0.005 ether}(fightId, 2);
        }

        vm.stopBroadcast();
    }

    // TODO: delete when finish tensting
    // function change() public {
    // vm.startBroadcast();
    //
    // address add = mtch;
    // collectionContract.setMatchmaker(add);
    // vm.stopBroadcast();
    // }

    // TODO: delete when finish tensting
    // function noneFIGHTIN() public {
    // vm.startBroadcast();
    //
    // collectionContract.nftFighting(1, false);
    // collectionContract.nftFighting(2, false);
    // collectionContract.nftFighting(3, false);
    // vm.stopBroadcast();
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
