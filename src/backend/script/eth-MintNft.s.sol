// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {PromptFightersNFT} from "../contracts/nft-contracts/eth-PromptFightersNft.sol";
import {LinkTokenInterface} from "@chainlink/shared/interfaces/LinkTokenInterface.sol";

import "../contracts/Utils.sol";

import {Script, console2} from "forge-std/Script.sol";
import "forge-std/console.sol";

/**
 * @dev Executes mintng and NFT process in Sepolia.
 */
contract MintNft is Script {
    PromptFightersNFT public collectionContract;
    LinkTokenInterface public i_LINK_TOKEN = LinkTokenInterface(ETH_SEPOLIA_LINK);

    function setUp() public virtual {
        collectionContract = PromptFightersNFT(DEPLOYED_SEPOLIA_COLLECTION);
    }

    function run() public virtual {
        vm.startBroadcast();
        i_LINK_TOKEN.approve(DEPLOYED_SEPOLIA_COLLECTION, 1 ether);
        collectionContract.safeMint(DEPLOYER, NFT_VALID_PROMPT);
        vm.stopBroadcast();
    }
}
