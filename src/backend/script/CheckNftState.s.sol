// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Executes sending an NFT from 1 chain to another..
// Addresse must posses enough LINK and ETH to execute the transactions.
// 10 LINK and 0.1 ETH should be enough.

import {PromptFightersNFT} from "../src/nft-contracts/eth-PromptFightersNft.sol";
import {FightersBarracks} from "../src/nft-contracts/avl-FightersBarracks.sol";

import "../src/Utils.sol";

import {Script, console2} from "forge-std/Script.sol";
import "forge-std/console.sol";

/**
 * @dev Executes mintng and NFT process in Ethereum.
 */
contract CheckNftState is Script {
    PromptFightersNFT public collectionContract;
    FightersBarracks public barracks;

    function setUp() public virtual {
        collectionContract = PromptFightersNFT(DEPLOYED_SEPOLIA_COLLECTION);
        barracks = FightersBarracks(DEPLOYED_FUJI_BARRACKS);
    }

    function run() public virtual {
        vm.startBroadcast();
        if (block.chainid == ETH_SEPOLIA_CHAIN_ID) {
            console.log(collectionContract.isNftOnChain(1));
            console.log(collectionContract.getOwnerOf(1));
            console.log(collectionContract.getPromptOf(1));
        }
        if (block.chainid == AVL_FUJI_CHAIN_ID) {
            console.log(barracks.isNftOnChain(1));
            console.log(barracks.getOwnerOf(1));
            console.log(barracks.getPromptOf(1));
        }
        vm.stopBroadcast();
    }
}
