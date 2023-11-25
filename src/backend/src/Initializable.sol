// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title Initializable
 * @author PromtFighters team: Carlos
 * @dev Used to safely intialize contracts that need each others addresses
 * in deployment.
 */
contract Initializable {
    bool s_isInitializedLock;

    // @dev: TODO This must be an address owned by the deployer of the system.
    address constant INTIALIZER_ADDRESS = address(777);

    /**
     * @dev Add in all functions that shouldn't be used before the other
     * contracts address is initialized.
     */
    modifier contractIsInitialized() {
        require(s_isInitializedLock, "Contract is not initialized.");
        _;
    }

    /**
     * @dev Add modifier in intialize() function the contract requries.
     */
    modifier initializeActions() {
        require(!s_isInitializedLock, "Contract already intialized.");
        require(msg.sender == INTIALIZER_ADDRESS, "You can't initialize the contract.");
        _;
        s_isInitializedLock = true;
    }
}
