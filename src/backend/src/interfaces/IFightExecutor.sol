// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IFightExecutor {
    event FightExecutor__Results(bytes indexed firstEnd, bytes indexed secondEnd);
    event FightExecutor__WinnerIs(bytes32 indexed fightId, address indexed winner, uint256 timestamp);

    // Calls Chainlink Functions, in the return calls VRF and in VRF return sets winner.
    function startFight(address[2] calldata participants, uint256[2] calldata nftIds) external;
}
