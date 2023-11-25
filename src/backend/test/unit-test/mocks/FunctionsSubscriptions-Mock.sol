// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

/// @title Chainlink Functions Subscription mock.
contract FunctionsSubscriptionsMock {
    mapping(address => uint64) s_addressToSubId;

    function createSubscription() external pure returns (uint64 subscriptionId) {
        return 0;
    }

    function addConsumer(uint64 subscriptionId, address consumer) external {
        s_addressToSubId[consumer] = subscriptionId;
    }
}
