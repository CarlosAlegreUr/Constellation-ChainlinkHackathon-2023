## Naming convention 📝

<details> <summary> Naming convention 📝 </summary>

If a smart contract starts with:

- `avl`-Name: means that contract will only be deployed in `Avalanche`.

- `eth`-Name: means that contract will only be deployed in `Ethereum`.

- `Name`: menas that contract will be deployed in `both chains`.

</details>

---

## Contracts' Structure 📜

<details> <summary> Contracts' Structure 📜 </summary>

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

    //************************ */
    // VIEW / PURE FUNCTIONS
    //************************ */
    // e.g., function getCount() public view returns (uint256) { ... }
}
```

</details>

---
