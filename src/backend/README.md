## Dependencies ⚙️

Forge install open zepelin contrats, chainlink contracts, forge-std.

Chainlink ccip contracts cant be installed with forge, create in your computer a different directory
and use npm or yarn to install them then coppy the node_modules folder inside the lib folder under the name
of node_modules_ccip.

forge install (name of other packages)

npm install @chainlink/contracts-ccip --save

## Naming convention 📝

If a smart contract starts with:

- `avl`-Name: means that contract will only be deployed in `Avalanche`.

- `eth`-Name: means that contract will only be deployed in `Ethereum`.

- `Name`: menas that contract will be deployed in `both chains`.

---

## Contracts' Structure 📜

```solidity
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// import "path/to/Dependency.sol";

/**
 * @title ContractTitle
 * @dev Brief description of the contract's purpose.
 * @notice Additional notices or warnings about the contract.
 */
contract ContractName {
    // Used libraries statements

    //******************************* */
    // CONTRACT'S STATE && CONSTANTS
    //******************************* */
    // e.g., uint256 private count;

    //******************** */
    // MODIFIERS
    //******************** */
    // e.g., modifier onlyOwner { ...; _; }

    //******************** */
    // CONSTRUCTOR
    //******************** */
    /**
     * @dev Constructor for initializing the contract.
     */
    constructor() {
        // Constructor code
    }

    //******************** */
    // EXTERNAL FUNCTIONS
    //******************** */
    // e.g., function externalFunction() external { ... }

    //******************** */
    // PUBLIC FUNCTIONS
    //******************** */
    // e.g., function publicFunction() public { ... }

    //******************** */
    // INTERNAL FUNCTIONS
    //******************** */
    // e.g., function internalFunction() internal { ... }

    //******************** */
    // PRIVATE FUNCTIONS
    //******************** */
    // e.g., function privateFunction() private { ... }

    //******************** */
    // VIEW / PURE FUNCTIONS
    //******************** */
    // e.g., function getCount() public view returns (uint256) { ... }
}
```

---
