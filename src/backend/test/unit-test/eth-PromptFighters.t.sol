// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Scenarios
import {ChainlinkMocksDeployed} from "./scenarios/ChainlinkMocksDeployed.t.sol";

import {IFightMatchmaker} from "../../src/interfaces/IFightMatchmaker.sol";

// Contract Tested
import {PromptFightersNFT} from "../../src/nft-contracts/eth-PromptFightersNft.sol";

// Useful values
import "../../src/Utils.sol";
import {UtilsValues} from "../Utils.t.sol";

import {Test, console2} from "forge-std/Test.sol";

contract PromptFightersNftTest is ChainlinkMocksDeployed, UtilsValues {
    PromptFightersNFT public promptFightersNFT;

    modifier initialized() {
        vm.prank(MOCK_INTIALIZER_ADDRESS);
        promptFightersNFT.initializeReceiver(MOCK_RECEIVER_ADDRESS);
        _;
    }

    function setUp() public override {
        super.setUp();
        promptFightersNFT =
        new PromptFightersNFT(address(funcsSubsMock), MOCK_FUNCS_SUBS_ID, ETH_SEPOLIA_CCIP_ROUTER,  IFightMatchmaker(address(0)));
    }

    function test_NothingBeforeInitialize() public {
        vm.expectRevert("Contract is not initialized.");
        promptFightersNFT.safeMint(MOCK_INTIALIZER_ADDRESS, VALID_PROMPT);

        vm.expectRevert("Contract is not initialized.");
        promptFightersNFT.sendNft(AVL_FUJI_SELECTOR, MOCK_RECEIVER_ADDRESS, "1");
    }
}
