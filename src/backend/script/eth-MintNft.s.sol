// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {PromptFightersNFT} from "../src/nft-contracts/eth-PromptFightersNft.sol";
import "../src/Utils.sol";

import {Script, console2} from "forge-std/Script.sol";
import "forge-std/console.sol";

/**
 * @dev Executes mintng and NFT process in Ethereum.
 */
contract MintNft is Script {
    PromptFightersNFT public COLLECTION_CONTRACT;

    function setUp() public virtual {}

    function run() public virtual {
        vm.broadcast();

        vm.stopBroadcast();
    }
}
