// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {BetsVault} from "../../contracts/BetsVault.sol";
import {FightMatchmaker} from "../../contracts/fight-contracts/FightMatchmaker.sol";
import {FightExecutor} from "../../contracts/fight-contracts/FightExecutor.sol";

import "../../contracts/Utils.sol";
import {DeploymentConfig} from "./DeploymentConfig.s.sol";
import "../../lib/forge-std/src/console.sol";

/**
 * @title DeployFightsContracts
 * @author @CarlosAlegreUr
 * @notice Deploys and initializes all contracts needed for the fight system but the ones
 * managing the NFTs. Doenst intialize Matchmaker that is done in Deployment.s.sol.
 */
contract DeployFightsContracts is DeploymentConfig {
    function setUp() public virtual override {
        super.setUp();
    }

    // @notice NO BROADCAST IS STARTED NEITHER STOPPED HERE, IT IS STARTED IN DEPLOYMENT.S.SOL run()
    function run() public virtual override {
        // Deploy Executor
        fightExecutor = new FightExecutor(funcs_router, vrf_router, fexecServicesInit);
        console.log("+++++++++++++++++++++++++++++++++++++++");
        console.log("+++++++++++++++++++++++++++++++++++++++");
        console.log("FightExecutor deployed at:");
        console.log(address(fightExecutor));
        console.log("+++++++++++++++++++++++++++++++++++++++");
        console.log("+++++++++++++++++++++++++++++++++++++++");

        // Deploy BetsVault
        betsVault = new BetsVault();
        console.log("+++++++++++++++++++++++++++++++++++++++");
        console.log("+++++++++++++++++++++++++++++++++++++++");
        console.log("BetsVault deployed at:");
        console.log(address(betsVault));
        console.log("+++++++++++++++++++++++++++++++++++++++");
        console.log("+++++++++++++++++++++++++++++++++++++++");

        // Deploy Matchmaker
        fightMatchmaker = new FightMatchmaker(link_token, automationBalanceThreshold);
        console.log("+++++++++++++++++++++++++++++++++++++++");
        console.log("+++++++++++++++++++++++++++++++++++++++");
        console.log("FightMatchmaker deployed at:");
        console.log(address(fightMatchmaker));
        console.log("+++++++++++++++++++++++++++++++++++++++");
        console.log("+++++++++++++++++++++++++++++++++++++++");

        // Initialize contracts
        address[] memory referencedContracts = new address[](2);
        referencedContracts[0] = address(fightMatchmaker);
        fightExecutor.initializeReferences(referencedContracts);
        betsVault.initializeReferences(referencedContracts);
    }
}
