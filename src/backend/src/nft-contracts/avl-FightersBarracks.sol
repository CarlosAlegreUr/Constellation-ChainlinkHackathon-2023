// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ICcipNftBridge} from "../interfaces/ICcipNftBridge.sol";

import {IRouterClient} from "@chainlink-ccip/src/v0.8/ccip/interfaces/IRouterClient.sol";
import {OwnerIsCreator} from "@chainlink-ccip/src/v0.8/shared/access/OwnerIsCreator.sol";
import {Client} from "@chainlink-ccip/src/v0.8/ccip/libraries/Client.sol";
import {CCIPReceiver} from "@chainlink-ccip/src/v0.8/ccip/applications/CCIPReceiver.sol";

contract FightersBarracks is CCIPReceiver, ICcipNftBridge {
    // CCIP nft tracking
    mapping(uint256 => bool) private s_canMove;
    mapping(uint256 => bool) private s_isOnChain;

    constructor(address _router) CCIPReceiver(_router) {}

    // Should have similar logic to the sendMessagePayLINK() of the chainlink docs
    // https://docs.chain.link/ccip/tutorials/send-arbitrary-data
    // In this repo there is an example of transferin NFT cross-chain:
    // https://github.com/smartcontractkit/ccip-starter-kit-foundry
    function sendNft(uint256 nftId) external {}

    function isNftOnChain(uint256 nftId) external view returns (bool) {
        return s_isOnChain[nftId];
    }

    // Set nft on chain
    function _ccipReceive(Client.Any2EVMMessage memory message) internal virtual override {}
}
