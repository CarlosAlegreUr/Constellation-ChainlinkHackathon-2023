// SPDX-License-Identifier: MIT

pragma solidity ^0.8.20;

import {Test, console2} from "forge-std/Test.sol";

contract UtilsValues is Test {
    address public constant MOCK_INTIALIZER_ADDRESS = address(777);
    address public MOCK_RECEIVER_ADDRESS = makeAddr("receiver-avl");
    address public MOCK_MATCHMAKER_ADDRESS = makeAddr("mock-matchmaker");
    address public MOCK_EXECUTOR_ADDRESS = makeAddr("mock-executor");

    uint64 public MOCK_FUNCS_SUBS_ID = 1;

    address public PLAYER_ONE = makeAddr("player1");
    address public PLAYER_TWO = makeAddr("player2");

    uint256 public FAKE_NFT_ID_ONE = 1;
    uint256 public FAKE_NFT_ID_TWO = 2;

    bytes32 public FIGHT_ID_ONE_TWO = keccak256(abi.encode(PLAYER_ONE, PLAYER_TWO, FAKE_NFT_ID_ONE, FAKE_NFT_ID_TWO));
    bytes32 public FIGHT_ID_ONE_ANYONE = keccak256(abi.encode(PLAYER_ONE, address(0), FAKE_NFT_ID_ONE, 0));

    string public constant VALID_PROMPT = "An NFT PROMPT";
}
