// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IFightMatchmaker} from "../interfaces/IFightMatchmaker.sol";
import {CcipNftBridge} from "../CcipNftBridge.sol";

import "../Utils.sol";

/**
 * @title FightersBarracks
 * @author PromtFighters team: Carlos
 * @dev Tracks ownership and NFTs' prompts for NFTs on chains
 * that are not the Ethereum one which has the official collection.
 */
contract FightersBarracks is CcipNftBridge {
    mapping(uint256 => address) private s_nftIdToOwner;
    mapping(uint256 => string) private s_nftIdToPrompt;

    constructor(address _router, address _receiverContract, IFightMatchmaker _fightMatchmaker)
        CcipNftBridge(ETH_SEPOLIA_SELECTOR, _receiverContract, _router, _fightMatchmaker)
    {
        require(_router == AVL_FUJI_CCIP_ROUTER, "Not allowed router.");
    }

    //******************** */
    // INTERNAL FUNCTIONS
    //******************** */

    function _updateNftStateOnSendChainSpecifics(uint256 _nftId) internal override {
        // Maybe delete if not needed, kept just in case.
        delete s_nftIdToOwner[_nftId];
        delete s_nftIdToPrompt[_nftId];
        emit ICCIPNftBridge__NftSent(msg.sender, AVL_FUJI_CHAIN_ID, _nftId, block.timestamp);
    }

    function _updateNftStateOnReceiveChainSpecifics(uint256 _nftId, address _owner, string memory _prompt) internal override {
        s_nftIdToOwner[_nftId] = _owner;
        s_nftIdToPrompt[_nftId] = _prompt;
        emit ICCIPNftBridge__NftReceived(_owner, AVL_FUJI_CHAIN_ID, _nftId, block.timestamp);
    }

    // Setters

    function setOwnerOf(uint256 _nftId, address _owner) internal override {
        if (_owner == address(0)) {
            delete s_nftIdToOwner[_nftId];
        } else {
            s_nftIdToOwner[_nftId] = _owner;
        }
    }

    function setPromptOf(uint256 _nftId, string memory _prompt) internal override {
        if (bytes(_prompt).length == 0) {
            delete s_nftIdToPrompt[_nftId];
        } else {
            s_nftIdToPrompt[_nftId] = _prompt;
        }
    }

    //************************ */
    // VIEW / PURE FUNCTIONS
    //************************ */

    function getOwnerOf(uint256 _nftId) public view override returns (address) {
        return s_nftIdToOwner[_nftId];
    }

    function getPromptOf(uint256 _nftId) public view override returns (string memory) {
        return s_nftIdToPrompt[_nftId];
    }
}
