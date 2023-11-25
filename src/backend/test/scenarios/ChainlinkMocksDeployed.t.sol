// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {FunctionsSubscriptionsMock} from "../unit-test/mocks/FunctionsSubscriptions-Mock.sol";
import {LinkTokenMock} from "../unit-test/mocks/LinkToken-Mock.sol";
import {Test, console2} from "forge-std/Test.sol";

contract ChainlinkMocksDeployed is Test {
    FunctionsSubscriptionsMock public funcsSubsMock;
    LinkTokenMock public linkTokenMock;

    function setUp() public virtual {
        funcsSubsMock = new FunctionsSubscriptionsMock();
        linkTokenMock = new LinkTokenMock();
    }
}
