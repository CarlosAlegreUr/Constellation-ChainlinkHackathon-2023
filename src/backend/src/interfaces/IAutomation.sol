// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

///////////////////////
// AUTOMATION CONFIG //
///////////////////////

interface ILogAutomation {
    // ESTO YO ENTIENDO QUE DEBERÍA UTILIZARSE EN registerUpkeep AL REGISTRAR
    // NUESTRO CONTRATO EN LA AUTOMATIZACIÓN,
    // PERO TODAVÍA NO HE DESCUBIERTO CÓMO SE HACE

    struct LogTriggerConfig {
        address contractAddress; // must have address that will be emitting the log
        uint8 filterSelector; // must have filtserSelector, denoting  which topics apply to filter ex 000, 101, 111...only last 3 bits apply
        bytes32 topic0; // must have signature of the emitted event
        bytes32 topic1; // optional filter on indexed topic 1
        bytes32 topic2; // optional filter on indexed topic 2
        bytes32 topic3; // optional filter on indexed topic 3
    }

    struct Log {
        uint256 index; // Index of the log in the block
        uint256 timestamp; // Timestamp of the block containing the log
        bytes32 txHash; // Hash of the transaction containing the log
        uint256 blockNumber; // Number of the block containing the log
        bytes32 blockHash; // Hash of the block containing the log
        address source; // Address of the contract that emitted the log
        bytes32[] topics; // Indexed topics of the log
        bytes data; // Data of the log
    }

    function checkLog(Log calldata log, bytes memory checkData)
        external
        returns (bool upkeepNeeded, bytes memory performData);

    function performUpkeep(bytes calldata performData) external;
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
