// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IFightMatchmaker} from "../interfaces/IFightMatchmaker.sol";
import {CcipNftBridge} from "../CcipNftBridge.sol";

import "../Utils.sol";

/**
 * @title FightersBarracks
 * @author PromtFighters team: @CarlosAlegreUr
 * @dev Tracks ownership and NFTs' prompts for NFTs on any EVM compatible chain.
 *
 * @notice This implementation allows for FUJI Avalanche testnet.
 * @notice To change it to other blockchain change the require statement in the constructor
 * that checks teh router for safety to the desired chain's router and pass it as
 * _router parameter.
 */
contract FightersBarracks is CcipNftBridge {
    //******************************* */
    // CONTRACT'S STATE && CONSTANTS
    //******************************* */

    mapping(uint256 => address) private s_nftIdToOwner;
    mapping(uint256 => string) private s_nftIdToPrompt;

    //******************** */
    // CONSTRUCTOR
    //******************** */

    constructor(address _router, address _receiverContract, IFightMatchmaker _fightMatchmaker)
        CcipNftBridge(ETH_SEPOLIA_SELECTOR, _receiverContract, _router, _fightMatchmaker)
    {
        require(_router == AVL_FUJI_CCIP_ROUTER, "Not allowed router.");
    }

    // TESTING ONLY
    // function setIsOnChain(uint256 nftId, bool isOnChain, string memory prompt) external {
    //     require(DEPLOYER == msg.sender);
    //     s_isOnChain[nftId] = isOnChain;
    //     s_nftIdToPrompt[nftId] = prompt;
    //     s_nftIdToOwner[nftId] = nftId == 2 ? PLAYER_FOR_FIGHTS : msg.sender;
    // }

    //******************** */
    // INTERNAL FUNCTIONS
    //******************** */

    function _updateNftStateOnSendChainSpecifics(uint256 _nftId) internal override {
        // Maybe delete if not needed, kept just in case.
        delete s_nftIdToOwner[_nftId];
        delete s_nftIdToPrompt[_nftId];
    }

    function _updateNftStateOnReceiveChainSpecifics(uint256 _nftId, address _owner, string memory _prompt)
        internal
        override
    {
        s_nftIdToOwner[_nftId] = _owner;
        s_nftIdToPrompt[_nftId] = _prompt;
    }

    // Setters

    /**
     * @dev Docs at CcipNftBridge.sol
     */
    function _setOwnerOf(uint256 _nftId, address _owner) internal override {
        if (_owner == address(0)) {
            delete s_nftIdToOwner[_nftId];
        } else {
            s_nftIdToOwner[_nftId] = _owner;
        }
    }

    /**
     * @dev Docs at CcipNftBridge.sol
     */
    function _setPromptOf(uint256 _nftId, string memory _prompt) internal override {
        if (bytes(_prompt).length == 0) {
            delete s_nftIdToPrompt[_nftId];
        } else {
            s_nftIdToPrompt[_nftId] = _prompt;
        }
    }

    //************************ */
    // VIEW / PURE FUNCTIONS
    //************************ */

    /**
     * @dev Docs at ICcipNftBridge.sol
     */
    function getOwnerOf(uint256 _nftId) public view override returns (address) {
        return s_nftIdToOwner[_nftId];
    }

    /**
     * @dev Docs at ICcipNftBridge.sol
     */
    function getPromptOf(uint256 _nftId) public view override returns (string memory) {
        return s_nftIdToPrompt[_nftId];
    }
}
