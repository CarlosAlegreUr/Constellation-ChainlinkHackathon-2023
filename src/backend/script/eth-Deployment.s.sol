// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {PromptFightersNFT} from "../src/nft-contracts/eth-PromptFightersNft.sol";

import {BetsVault} from "../src/BetsVault.sol";
import {FightMatchmaker} from "../src/fight-contracts/FightMatchmaker.sol";
import {FightExecutor} from "../src/fight-contracts/FightExecutor.sol";

import "../src/Utils.sol";

import {Script, console2} from "forge-std/Script.sol";
import "forge-std/console.sol";

contract PromptFightersDeploy is Script {
    function setUp() public {}

    function run() public {
        vm.broadcast();
        // Deploy collection
        PromptFightersNFT promptFighters = new PromptFightersNFT(ETH_SEPOLIA_FUNCTIONS_ROUTER, ETH_SEPOLIA_CCIP_ROUTER);
        console.log("PromptFighters deployed at:");
        console.log(address(promptFighters));

        // Deploy Executor
        FightExecutor fightExecutor = new FightExecutor(ETH_SEPOLIA_FUNCTIONS_ROUTER, ETH_SEPOLIA_VRF_COORDINATOR);
        console.log("FightExecutor deployed at:");
        console.log(address(fightExecutor));

        // Deploy BetsVault
        BetsVault betsVault = new BetsVault();
        console.log("BetsVault deployed at:");
        console.log(address(betsVault));

        // Deploy Matchmaker
        FightMatchmaker fightMatchmaker = new FightMatchmaker();
        console.log("FightMatchmaker deployed at:");
        console.log(address(fightMatchmaker));

        // Initialize contracts
        fightExecutor.initializeMatchmaker(fightMatchmaker);
        fightMatchmaker.initializeContracts(fightExecutor, betsVault);
        betsVault.initializeMatchmaker(fightMatchmaker);
        
        vm.stopBroadcast();
    }
}
