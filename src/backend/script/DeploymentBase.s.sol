// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {PromptFightersNFT} from "../contracts/nft-contracts/eth-PromptFightersNft.sol";

import {BetsVault} from "../contracts/BetsVault.sol";
import {FightMatchmaker} from "../contracts/fight-contracts/FightMatchmaker.sol";
import {FightExecutor} from "../contracts/fight-contracts/FightExecutor.sol";

import "../contracts/Utils.sol";

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
        address[] memory referencedContracts = new address[](2);
        referencedContracts[0] = address(fightMatchmaker);
        fightExecutor.initializeReferences(referencedContracts);
        betsVault.initializeReferences(referencedContracts);

        referencedContracts[0] = address(fightExecutor);
        referencedContracts[1] = address(betsVault);
        fightMatchmaker.initializeReferences(referencedContracts);
    }
}
