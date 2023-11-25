// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

// Scenarios
import {ChainlinkMocksDeployed} from "./scenarios/ChainlinkMocksDeployed.t.sol";

import {IFightMatchmaker} from "../../src/interfaces/IFightMatchmaker.sol";

// Contract Tested
import {BetsVault} from "../../src/BetsVault.sol";

// Useful values
import "../../src/Utils.sol";
import "../Utils.t.sol";

import {Test} from "forge-std/Test.sol";
import "forge-std/console.sol";

// All capital letter variable come from Utils.t.sol.
contract BetsVaultTest is Test, UtilsValues {
    BetsVault public betsVault;

    modifier initialized() {
        vm.prank(MOCK_INTIALIZER_ADDRESS);
        betsVault.initializeMatchmaker(IFightMatchmaker(MOCK_MATCHMAKER_ADDRESS));
        _;
    }

    function setUp() public {
        betsVault = new BetsVault();
    }

    function test_NothingBeforeInitialized() public {
        vm.expectRevert("Contract is not initialized.");
        betsVault.lockBet(FIGHT_ID_ONE_TWO, PLAYER_ONE);

        vm.expectRevert("Contract is not initialized.");
        betsVault.unlockAndRetrieveBet(FIGHT_ID_ONE_TWO);

        vm.expectRevert("Contract is not initialized.");
        betsVault.distributeBetsPrize(FIGHT_ID_ONE_TWO, PLAYER_ONE);
    }

    function _lockFundsFor(bytes32 _fightId, address _player, uint256 amount) private {
        vm.deal(MOCK_MATCHMAKER_ADDRESS, amount);
        vm.prank(MOCK_MATCHMAKER_ADDRESS);
        betsVault.lockBet{value: amount}(_fightId, _player);
    }

    function test_LockFundsCorrectly() public initialized {
        // First call should set requester
        _lockFundsFor(FIGHT_ID_ONE_TWO, PLAYER_ONE, 1 ether);

        BetsVault.BetsState memory _state = betsVault.getBetsState(FIGHT_ID_ONE_TWO);

        assert(_state.requester == PLAYER_ONE);
        assert(_state.requesterBet == 1 ether);
        assert(_state.acceptorBet == 0);
        assert(_state.areBetsLocked);

        // Second call should set acceptor
        _lockFundsFor(FIGHT_ID_ONE_TWO, PLAYER_TWO, 1 ether);

        _state = betsVault.getBetsState(FIGHT_ID_ONE_TWO);

        assert(_state.requesterBet == 1 ether);
        assert(_state.acceptorBet == 1 ether);
        assert(_state.acceptor == PLAYER_TWO);
        assert(_state.areBetsLocked);
    }

    function test_DistributePrizesCorrectly() public initialized {
        _lockFundsFor(FIGHT_ID_ONE_TWO, PLAYER_ONE, 1 ether);
        _lockFundsFor(FIGHT_ID_ONE_TWO, PLAYER_TWO, 1 ether);

        uint256 prevBalance = PLAYER_ONE.balance;

        vm.prank(MOCK_MATCHMAKER_ADDRESS);
        betsVault.distributeBetsPrize(FIGHT_ID_ONE_TWO, PLAYER_ONE);

        uint256 currentBalance = PLAYER_ONE.balance;

        assert(prevBalance < currentBalance);
        assert(prevBalance + 2 ether == currentBalance);
    }
}
