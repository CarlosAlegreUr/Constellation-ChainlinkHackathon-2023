// // SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Scenarios
import {ChainlinkMocksDeployed} from "./scenarios/ChainlinkMocksDeployed.t.sol";

import {IFightMatchmaker} from "../../contracts/interfaces/IFightMatchmaker.sol";

// Contract Tested
import {PromptFightersNFT} from "../../contracts/nft-contracts/eth-PromptFightersNft.sol";

// Useful values
import "../../contracts/Utils.sol";
import {UtilsValues} from "../Utils.t.sol";

import {Test, console2} from "forge-std/Test.sol";

contract PromptFightersNftTest is ChainlinkMocksDeployed, UtilsValues {
    PromptFightersNFT public promptFightersNFT;

    modifier initialized() {
        address[] memory referencedContracts = new address[](1);
        referencedContracts[0] = MOCK_RECEIVER_ADDRESS;
        vm.prank(MOCK_INTIALIZER_ADDRESS);
        promptFightersNFT.initializeReferences(referencedContracts);
        _;
    }

    function setUp() public override {
        super.setUp();
        promptFightersNFT = new PromptFightersNFT(
            address(funcsSubsMock), MOCK_FUNCS_SUBS_ID, ETH_SEPOLIA_CCIP_ROUTER, IFightMatchmaker(address(0))
        );
    }

    function test_NothingBeforeInitialize() public {
        vm.expectRevert("Contract is not initialized.");
        promptFightersNFT.safeMint(MOCK_INTIALIZER_ADDRESS, VALID_PROMPT);

        vm.expectRevert("Contract is not initialized.");
        promptFightersNFT.sendNft(2);
    }
}
