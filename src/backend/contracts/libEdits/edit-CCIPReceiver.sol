// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

///********************************* */
//  ATTENTION ❗❗❗❗❗❗❗❗❗
//
// This CCIP contract is exacly the same of Chainlink
// but with small modification so is compatible with Chainlink Funcitons.abi
//
// A contract that uses both has inconsistencies like:
//
// 1.- IERC165 in Chainlink Functions its a view function.
// In CCIP is a pure function.
// So if a contract uses both there is a conflict.
// This CCIP contract modified so IERC165 func is view as with functions.
//
// 2.- There is a variable clash, both have an immutable vairbale with the same
// name i_router.
// In this CCIP contract i_router now is --> i_routerCCIPnameChanged
//
// /********************************** */

import {IAny2EVMMessageReceiver} from "@chainlink-ccip/src/v0.8/ccip/interfaces/IAny2EVMMessageReceiver.sol";
import {Client} from "@chainlink-ccip/src/v0.8/ccip/libraries/Client.sol";
import {IERC165} from "@chainlink-ccip/src/v0.8/vendor/openzeppelin-solidity/v4.8.0/utils/introspection/IERC165.sol";

/// @title CCIPReceiver - Base contract for CCIP applications that can receive messages.
abstract contract CCIPReceiver is IAny2EVMMessageReceiver, IERC165 {
    address internal immutable i_routerCCIPnameChanged; // @notice Name changed to avoid chainlink funcs collision

    constructor(address router) {
        if (router == address(0)) revert InvalidRouter(address(0));
        i_routerCCIPnameChanged = router;
    }

    /// @notice IERC165 supports an interfaceId
    /// @param interfaceId The interfaceId to check
    /// @return true if the interfaceId is supported
    // @dev I HAD TO ADD VIRTUAL HERE
    function supportsInterface(bytes4 interfaceId)
        public
        view
        /**
         * @notice Changed to view for funcs compatibility
         */
        virtual
        override
        returns (bool)
    {
        return interfaceId == type(IAny2EVMMessageReceiver).interfaceId || interfaceId == type(IERC165).interfaceId;
    }

    /// @inheritdoc IAny2EVMMessageReceiver
    function ccipReceive(Client.Any2EVMMessage calldata message) external virtual override onlyRouter {
        _ccipReceive(message);
    }

    /// @notice Override this function in your implementation.
    /// @param message Any2EVMMessage
    function _ccipReceive(Client.Any2EVMMessage memory message) internal virtual;

    /////////////////////////////////////////////////////////////////////
    // Plumbing
    /////////////////////////////////////////////////////////////////////

    /// @notice Return the current router
    /// @return i_routerCCIPnameChanged address
    function getRouter() public view returns (address) {
        return address(i_routerCCIPnameChanged);
    }

    error InvalidRouter(address router);

    /// @dev only calls from the set router are accepted.
    modifier onlyRouter() {
        if (msg.sender != address(i_routerCCIPnameChanged)) revert InvalidRouter(msg.sender);
        _;
    }
}
