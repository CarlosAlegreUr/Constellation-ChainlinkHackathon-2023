// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IFightMatchmaker} from "../interfaces/IFightMatchmaker.sol";

contract FightMatchmaker is IFightMatchmaker {
    mapping(bytes32 => FightState) s_fightIdToState;
    mapping(address => uint256) s_userToNonce;

    function searchFight(uint256 _nftId) external {
        uint256 userNonce = s_userToNonce[msg.sender];
        bytes32 fightId = keccak256(abi.encode(msg.sender, _nftId, userNonce));
        FightState newState = FightState.Requested;
        s_fightIdToState[fightId] = newState;
        emit FightMatchmaker__FightRequested(msg.sender, _nftId, msg.value);
    }

    function acceptFight() external {
        emit FightMatchmaker__FightRequested(msg.sender, 0, msg.value);
    }
}
