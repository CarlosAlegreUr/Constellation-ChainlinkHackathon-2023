// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Scenarios
import {ChainlinkMocksDeployed} from "../scenarios/ChainlinkMocksDeployed.t.sol";

// Contract Tested
import {PromptFightersNFT} from "../../src/nft-contracts/eth-PromptFightersNft.sol";

// Useful values
import "../../src/Utils.sol";
import "../Utils.t.sol";

import {Test, console2} from "forge-std/Test.sol";

contract PromptFightersNftTest is ChainlinkMocksDeployed {
    PromptFightersNFT public promptFightersNFT;
    address public RECEIVER_ADDRESS = makeAddr("receiver-avl");
    address constant INTIALIZER_ADDRESS = address(777);

    modifier initialized() {
        vm.prank(INTIALIZER_ADDRESS);
        promptFightersNFT.initializeReceiver(RECEIVER_ADDRESS);
        _;
    }

    function setUp() public override {
        super.setUp();
        promptFightersNFT = new PromptFightersNFT(address(funcsSubsMock), ETH_SEPOLIA_CCIP_ROUTER);
    }

    function test_NothingBeforeInitialize() public {
        vm.expectRevert("Contract is not initialized.");
        promptFightersNFT.safeMint(INTIALIZER_ADDRESS, VALID_PROMT);

        vm.expectRevert("Contract is not initialized.");
        promptFightersNFT.sendNft(AVL_FUJI_SELECTOR, RECEIVER_ADDRESS, "1");
    }
}
