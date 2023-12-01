// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Scenarios
import {ChainlinkMocksDeployed} from "./scenarios/ChainlinkMocksDeployed.t.sol";

// Contract Tested
import {FightMatchmaker} from "../../contracts/fight-contracts/FightMatchmaker.sol";

// Contract interacted with
import {BetsVault} from "../../contracts/BetsVault.sol";
import {IBetsVault} from "../../contracts/interfaces/IBetsVault.sol";
import {IFightExecutor} from "../../contracts/interfaces/IFightExecutor.sol";
import {IFightMatchmaker} from "../../contracts/interfaces/IFightMatchmaker.sol";

// Useful values
import "../../contracts/Utils.sol";
import "../Utils.t.sol";

import "forge-std/console.sol";

// All capital letter variable come from Utils.t.sol.
contract FightMatchmakerTest is UtilsValues {
    FightMatchmaker public fightMatchmaker;
    BetsVault public betsVault;

    modifier initialized() {
        address[] memory referencedContracts = new address[](2);
        referencedContracts[0] = address(fightMatchmaker);
        vm.startPrank(MOCK_INTIALIZER_ADDRESS);
        betsVault.initializeReferences(referencedContracts);
        referencedContracts[0] = MOCK_EXECUTOR_ADDRESS;
        referencedContracts[1] = address(betsVault);
        fightMatchmaker.initializeReferences(referencedContracts);
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
