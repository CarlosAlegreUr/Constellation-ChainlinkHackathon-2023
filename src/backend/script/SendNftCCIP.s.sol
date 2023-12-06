// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {PromptFightersNFT} from "../contracts/nft-contracts/eth-PromptFightersNft.sol";
import {FightersBarracks} from "../contracts/nft-contracts/avl-FightersBarracks.sol";
import {FightMatchmaker} from "../contracts/fight-contracts/FightMatchmaker.sol";

import "../contracts/Utils.sol";

import {Script, console2} from "forge-std/Script.sol";
import "forge-std/console.sol";

/**
 * @dev Sends NFTs from Sepolia to Avalanche Fuji
 */
contract SendNftCcip is Script {
    PromptFightersNFT public collectionContract;
    FightersBarracks public barracks;

    uint256 constant NFT_ID_TO_SEND = 1; // 1 || 4

    function setUp() public {
        collectionContract = PromptFightersNFT(DEPLOYED_SEPOLIA_COLLECTION);
        barracks = FightersBarracks(DEPLOYED_FUJI_BARRACKS);
    }

    function run() public {
        vm.startBroadcast();
        if (block.chainid == ETH_SEPOLIA_CHAIN_ID) {
            collectionContract.sendNft{value: SEND_NFT_PRICE}(NFT_ID_TO_SEND);
        }
        if (block.chainid == AVL_FUJI_CHAIN_ID) {
            barracks.sendNft{value: SEND_NFT_PRICE_FUJI}(NFT_ID_TO_SEND);
        }
        vm.stopBroadcast();
    }

    // NOTE: Accelerate the process during testing
    function setNftOnBarracks() public {
        if (block.chainid == AVL_FUJI_CHAIN_ID) {
            vm.startBroadcast();
            barracks.setIsOnChain(NFT_ID_TO_SEND, true, "someone-very-happy-because-yes");
            vm.stopBroadcast();
        } else {
            console.log("This script function runs only on Avalanche Fuji");
        }
    }

    // NOTE: sometimes contracts dont verify on Snowflake, the use this.
    function checkBarracksNftState() public {
        vm.startBroadcast();
        if (block.chainid == AVL_FUJI_CHAIN_ID) {
            console.log("Checking NFT ID: ", NFT_ID_TO_SEND);
            console.log("Owner is:");
            console.log(barracks.getOwnerOf(NFT_ID_TO_SEND));
            console.log("Prompt is:");
            console.log(barracks.getPromptOf(NFT_ID_TO_SEND));
            console.log("Is on chain:");
            console.log(barracks.getIsNftOnChain(NFT_ID_TO_SEND));
            console.log("Is fighting:");
            console.log(barracks.getIsNftFighting(NFT_ID_TO_SEND));
            console.log("Is automated:");
            FightMatchmaker fm = FightMatchmaker(FUJI_FIGHT_MATCHMAKER);
            console.log(fm.getNftIdAutomated() == NFT_ID_TO_SEND);

            console.log(fm.getBetsVault());
            console.log(fm.getFightExecutorContract());

            console.log(barracks.getMatchmaker());

            console.log(fm.getContractUpkeepId());

            vm.stopBroadcast();
        } else {
            console.log("Thi script function runs only on Avalanche Fuji");
        }
    }
}
