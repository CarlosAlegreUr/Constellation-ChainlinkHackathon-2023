// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IAutomationForwarder} from "@chainlink/automation/interfaces/IAutomationForwarder.sol";

///////////////////////
// AUTOMATION CONFIG //
///////////////////////

/**
 * @title Automation Interfaces
 * @author @arynyestos
 * @notice Interfaces to make Automation params more clear.
 */
interface IAutomationRegistrar {
    struct RegistrationParams {
        string name; // Name of upkeep that will be displayed in the UI.
        bytes encryptedEmail; // Can leave blank. If registering via UI we will encrypt email and store it here.
        address upkeepContract; // Address of your Automation-compatible contract
        uint32 gasLimit; // The maximum gas limit that will be used for your txns. Rather over-estimate gas since you only pay for what you use, while too low gas might mean your upkeep doesn't perform. Trade-off is higher gas means higher minimum funding requirement.
        address adminAddress; // The address that will have admin rights for this upkeep. Use your wallet address, unless you want to make another wallet the admin.
        uint8 triggerType; // 0 is Conditional upkeep, 1 is Log trigger upkeep
        bytes checkData; // checkData is a static input that you can specify now which will be sent into your checkUpkeep or checkLog, see interface.
        bytes triggerConfig; // The configuration for your upkeep. 0x for conditional upkeeps. For log triggers: abi.encode(address contractAddress, uint8 filterSelector,bytes32 topic0,bytes32 topic1,bytes32 topic2, bytes32 topic3);
        bytes offchainConfig; // 	Leave as 0x, placeholder parameter for future.
        uint96 amount; // Ensure this is less than or equal to the allowance just given, and needs to be in WEI.
    }

    function registerUpkeep(RegistrationParams calldata requestParams) external returns (uint256);
}

interface IAutomationRegistry {
    function getForwarder(uint256 upkeepID) external view returns (IAutomationForwarder);
    function addFunds(uint256 id, uint96 amount) external;
}
