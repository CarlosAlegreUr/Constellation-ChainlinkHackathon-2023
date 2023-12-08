// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {FunctionsSubscriptionsMock} from "../mocks/FunctionsSubscriptions-Mock.sol";
import {Test, console2} from "forge-std/Test.sol";

contract ChainlinkMocksDeployed is Test {
    FunctionsSubscriptionsMock public funcsSubsMock;

    function setUp() public virtual {
        funcsSubsMock = new FunctionsSubscriptionsMock();
    }
}
