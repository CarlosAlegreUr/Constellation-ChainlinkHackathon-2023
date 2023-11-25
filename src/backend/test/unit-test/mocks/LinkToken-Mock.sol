// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract LinkTokenMock {
    uint256 private constant TOTAL_SUPPLY = 1_000_000_000 * 1e18;

    mapping(address => uint256) s_balances;

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        s_balances[from] += amount;
        s_balances[to] += amount;
        return true;
    }
}
