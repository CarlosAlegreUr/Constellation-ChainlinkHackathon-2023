// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {PromptFightersNFT} from "../src/nft-contracts/eth-PromptFightersNft.sol";

import {BetsVault} from "../src/BetsVault.sol";
import {FightMatchmaker} from "../src/fight-contracts/FightMatchmaker.sol";
import {FightExecutor} from "../src/fight-contracts/FightExecutor.sol";

import "../src/Utils.sol";

import {Script, console2} from "forge-std/Script.sol";
import "forge-std/console.sol";

contract DeployFightsContracts is Script {
    address public funcs_router;
    uint64 public funcs_subsId;
    address public vrf_router;

    FightMatchmaker public fightMatchmaker;

    function setUp() public virtual {}

    // @notice NO BROADCAST IS STARTED NEITHER STOPPED HERE
    function run() public virtual {
        // Deploy Executor
        FightExecutor fightExecutor = new FightExecutor(funcs_router, funcs_subsId, vrf_router);
        console.log("FightExecutor deployed at:");
        console.log(address(fightExecutor));

        // Deploy BetsVault
        BetsVault betsVault = new BetsVault();
        console.log("BetsVault deployed at:");
        console.log(address(betsVault));

        // Deploy Matchmaker
        fightMatchmaker = new FightMatchmaker();
        console.log("FightMatchmaker deployed at:");
        console.log(address(fightMatchmaker));

        // Initialize contracts
        fightExecutor.initializeMatchmaker(fightMatchmaker);
        fightMatchmaker.initializeContracts(fightExecutor, betsVault);
        betsVault.initializeMatchmaker(fightMatchmaker);
    }
}
