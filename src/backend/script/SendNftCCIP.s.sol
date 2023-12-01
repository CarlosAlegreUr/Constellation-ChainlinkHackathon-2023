// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Executes sending an NFT from 1 chain to another..
// Addresse must posses enough LINK and ETH to execute the transactions.
// 10 LINK and 0.1 ETH should be enough.

import {PromptFightersNFT} from "../contracts/nft-contracts/eth-PromptFightersNft.sol";
import {FightersBarracks} from "../contracts/nft-contracts/avl-FightersBarracks.sol";

import "../contracts/Utils.sol";

import {Script, console2} from "forge-std/Script.sol";
import "forge-std/console.sol";

/**
 * @dev Executes mintng and NFT process in Ethereum.
 */
contract SendNftCcip is Script {
    PromptFightersNFT public collectionContract;
    FightersBarracks public barracks;

    function setUp() public virtual {
        collectionContract = PromptFightersNFT(DEPLOYED_SEPOLIA_COLLECTION);
        barracks = FightersBarracks(DEPLOYED_FUJI_BARRACKS);
    }

    function run() public virtual {
        vm.startBroadcast();
        if (block.chainid == ETH_SEPOLIA_CHAIN_ID) {
            collectionContract.sendNft{value: SEND_NFT_PRICE}(1);
        }
        if (block.chainid == AVL_FUJI_CHAIN_ID) {
            barracks.sendNft{value: SEND_NFT_PRICE_FUJI}(1);
        }
        vm.stopBroadcast();
    }
}
