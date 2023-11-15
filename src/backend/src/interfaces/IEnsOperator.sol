// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IEnsOperator {
    // Events
    event IEnsOperatorr__PlayerRegistered(address indexed player, string indexed name, uint256 timestamp);
    event IEnsOperatorr__NftRegistered(uint256 indexed nftId, string indexed name, address owner, uint256 timestamp);

    // Functions interact with ENS.
    function registerUsername(string calldata username) external;
    function registerFighterName(string calldata nftName) external;

    // Getters
    function getAddressUsername(address user) external returns (string memory);
    function getNftIdName(uint256 user) external returns (string memory);

    // Checkers (if not registered returned address 0 and nftId 0, id 0 must never be assigned in collection)
    function isUsernameRegistered(string calldata username) external returns (bool, address);
    function isNftNameRegistered(string calldata nftName) external returns (bool, uint256);
}
