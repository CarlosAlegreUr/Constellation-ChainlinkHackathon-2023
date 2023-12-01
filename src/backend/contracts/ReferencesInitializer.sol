// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./Utils.sol";

/**
 * @title Initializable
 * @author PromtFighters team: Carlos
 * @dev Used to safely intialize contracts that reference each other
 * but none of them are deployed yet.
 */
abstract contract ReferencesInitializer {
    bool s_isInitializedLock;

    // @dev: This must be an address owned by the deployer of the system.
    address constant INTIALIZER_ADDRESS = DEPLOYER;

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

    /**
     * @dev 1 time use function that must have the iniitalizeActions() modifier
     * wherever it is overriden. 
     * 
     * Must initialize the not known at deploy time referenced contracts.
     * 
     * @notice Can only be called by INTIALIZER_ADDRESS.
     * @notice A 2 step setting process would be safer, one for proposing the address
     * and one for confirming it and then indeed lock the setter forever. But this is
     * a simple PoC.
     */
    function initializeReferences(address[] calldata externalReferences) external virtual;
}
