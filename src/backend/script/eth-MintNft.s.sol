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
        if (block.chainid == ETH_SEPOLIA_CHAIN_ID) {
            console.log("We are in SEPOLIA ETH");

            // Send LINK to collection to pay for the NFT Verification Fee with Chainlink Functions
            i_LINK_TOKEN.transfer(DEPLOYED_SEPOLIA_COLLECTION, MINT_NFT_LINK_FEE);
            collectionContract.safeMint(msg.sender, NFT_VALID_PROMPT);

            console.log("Minting process started successfully...");
            console.log("What for Functions response to be actually minted.");

            vm.stopBroadcast();
        } else {
            console.log("Mint script can only run in Sepolia.");
        }
    }
}
