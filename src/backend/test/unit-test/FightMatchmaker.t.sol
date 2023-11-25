// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Scenarios
import {ChainlinkMocksDeployed} from "./scenarios/ChainlinkMocksDeployed.t.sol";

// Contract Tested
import {FightMatchmaker} from "../../src/fight-contracts/FightMatchmaker.sol";

// Contract interacted with
import {BetsVault} from "../../src/BetsVault.sol";
import {IBetsVault} from "../../src/interfaces/IBetsVault.sol";
import {IFightExecutor} from "../../src/interfaces/IFightExecutor.sol";
import {IFightMatchmaker} from "../../src/interfaces/IFightMatchmaker.sol";

// Useful values
import "../../src/Utils.sol";
import "../Utils.t.sol";

import "forge-std/console.sol";

// All capital letter variable come from Utils.t.sol.
contract FightMatchmakerTest is UtilsValues {
    FightMatchmaker public fightMatchmaker;
    BetsVault public betsVault;

    modifier initialized() {
        vm.startPrank(MOCK_INTIALIZER_ADDRESS);
        fightMatchmaker.initializeContracts(IFightExecutor(MOCK_EXECUTOR_ADDRESS), betsVault);
        betsVault.initializeMatchmaker(fightMatchmaker);
        vm.stopPrank();
        _;
    }

    function setUp() public {
        fightMatchmaker = new FightMatchmaker();
        betsVault = new BetsVault();
    }

    function test_NothingBeforeInitialized() public {
        FightMatchmaker.FightRequest memory freq;
        vm.expectRevert("Contract is not initialized.");
        fightMatchmaker.requestFight(freq);

        vm.expectRevert("Contract is not initialized.");
        fightMatchmaker.acceptFight(FIGHT_ID_ONE_TWO, FAKE_NFT_ID_TWO);

        vm.expectRevert("Contract is not initialized.");
        fightMatchmaker.setFightState(FIGHT_ID_ONE_TWO, IFightMatchmaker.FightState.AVAILABLE, 2);
    }

    // TODO: if enough time add tests with a mock Collection that doesnt
    // require DON service to mint NFTs and test other functionalities
    // like requestFight()
}
