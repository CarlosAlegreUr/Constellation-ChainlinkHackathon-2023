// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {PromptFightersNFT} from "../contracts/nft-contracts/eth-PromptFightersNft.sol";
import {FightersBarracks} from "../contracts/nft-contracts/avl-FightersBarracks.sol";

import "../contracts/Utils.sol";

import {Script, console2} from "forge-std/Script.sol";
import "forge-std/console.sol";

/**
 * @dev Sends NFTs from Sepolia to Avalanche Fuji
 */
contract SendNftCcip is Script {
    PromptFightersNFT public collectionContract;
    FightersBarracks public barracks;

    uint256 constant NFT_ID_TO_SEND = 3;

    function setUp() public virtual {
        collectionContract = PromptFightersNFT(DEPLOYED_SEPOLIA_COLLECTION);
        barracks = FightersBarracks(DEPLOYED_FUJI_BARRACKS);
    }

    function run() public virtual {
        vm.startBroadcast();
        if (block.chainid == ETH_SEPOLIA_CHAIN_ID) {
            collectionContract.sendNft{value: SEND_NFT_PRICE}(NFT_ID_TO_SEND);
        }
        if (block.chainid == AVL_FUJI_CHAIN_ID) {
            barracks.sendNft{value: SEND_NFT_PRICE_FUJI}(NFT_ID_TO_SEND);
        }
        vm.stopBroadcast();
    }
}
