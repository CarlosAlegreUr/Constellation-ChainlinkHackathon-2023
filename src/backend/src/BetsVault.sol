// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IBetsVault} from "./interfaces/IBetsVault.sol";

//************************************** */
//            FOR DEVS!
// This contract might need more state
// variables or interface functions.
//
// Feel free to add them if you deem it
// necessary.
//************************************** */

contract BetsVault is IBetsVault {
    mapping(bytes32 => BetsState) s_fightIdToBetState;

    // Functions ONLY called by requestFight from matchmaker.
    function lockBet(address player) external payable {}
    function unlockBet(address player) external payable {}

    function checkBetsAreValid(bytes32 _fightId, address _userOne, uint256 _betOne, address _userTwo, uint256 _betTwo)
        external
        returns (bool)
    {}

    // Internal funcs

    function _getIsBetUnlockable(BetsState calldata _state) internal returns (bool) {}

    // Setters
    function setBetState(uint256 _fightId, BetsState calldata _state) external {}

    // Getters
    function getBet(address _user, bytes32 _fightId) external returns (uint256) {}
}
