// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IAutomationForwarder} from "@chainlink/automation/interfaces/IAutomationForwarder.sol";

///////////////////////
// AUTOMATION CONFIG //
///////////////////////

// TODO: DELETE LATER log trigger struct
struct LogTriggerConfig {
    address contractAddress; // must have address that will be emitting the log
    uint8 filterSelector; // must have filtserSelector, denoting  which topics apply to filter ex 000, 101, 111...only last 3 bits apply
    bytes32 topic0; // must have signature of the emitted event
    bytes32 topic1; // optional filter on indexed topic 1
    bytes32 topic2; // optional filter on indexed topic 2
    bytes32 topic3; // optional filter on indexed topic 3
}

// TODO: Delete later Log struct
/**
 * @member index the index of the log in the block. 0 for the first log
 * @member timestamp the timestamp of the block containing the log
 * @member txHash the hash of the transaction containing the log
 * @member blockNumber the number of the block containing the log
 * @member blockHash the hash of the block containing the log
 * @member source the address of the contract that emitted the log
 * @member topics the indexed topics of the log
 * @member data the data of the log
 */
struct Log {
    uint256 index;
    uint256 timestamp;
    bytes32 txHash;
    uint256 blockNumber;
    bytes32 blockHash;
    address source;
    bytes32[] topics;
    bytes data;
}

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
}
