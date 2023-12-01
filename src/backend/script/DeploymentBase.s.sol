// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {PromptFightersNFT} from "../contracts/nft-contracts/eth-PromptFightersNft.sol";

import {BetsVault} from "../contracts/BetsVault.sol";
import {FightMatchmaker} from "../contracts/fight-contracts/FightMatchmaker.sol";
import {FightExecutor} from "../contracts/fight-contracts/FightExecutor.sol";

import "../contracts/Utils.sol";

import {Script, console2} from "forge-std/Script.sol";
import "forge-std/console.sol";

contract DeployFightsContracts is Script {
    address public funcs_router;
    uint64 public funcs_subsId;
    address public vrf_router;
    
    address public link_token;
    address public automationRegistry;
    address public automationRegistrar;
    uint256 public automationBalanceThreshold;

    //   struct RegistrationParams {
    //     string name; // Name of upkeep that will be displayed in the UI.
    //     bytes encryptedEmail; // Can leave blank. If registering via UI we will encrypt email and store it here.
    //     address upkeepContract; // Address of your Automation-compatible contract
    //     uint32 gasLimit; // The maximum gas limit that will be used for your txns. Rather over-estimate gas since you only pay for what you use, while too low gas might mean your upkeep doesn't perform. Trade-off is higher gas means higher minimum funding requirement.
    //     address adminAddress; // The address that will have admin rights for this upkeep. Use your wallet address, unless you want to make another wallet the admin.
    //     uint8 triggerType; // 0 is Conditional upkeep, 1 is Log trigger upkeep
    //     bytes checkData; // checkData is a static input that you can specify now which will be sent into your checkUpkeep or checkLog, see interface.
    //     bytes triggerConfig; // The configuration for your upkeep. 0x for conditional upkeeps. For log triggers: abi.encode(address contractAddress, uint8 filterSelector,bytes32 topic0,bytes32 topic1,bytes32 topic2, bytes32 topic3);
    //     bytes offchainConfig; // 	Leave as 0x, placeholder parameter for future.
    //     uint96 amount; // Ensure this is less than or equal to the allowance just given, and needs to be in WEI.
    // }

    FightMatchmaker public fightMatchmaker;

    function setUp() public virtual {}

    // @notice NO BROADCAST IS STARTED NEITHER STOPPED HERE
    function run() public virtual {
        // Deploy Executor
        FightExecutor fightExecutor = new FightExecutor(funcs_router, funcs_subsId, vrf_router);
        console.log("FightExecutor deployed at:");
        console.log(address(fightExecutor));

        // Deploy BetsVault
        BetsVault betsVault = new BetsVault();
        console.log("BetsVault deployed at:");
        console.log(address(betsVault));

        // Deploy Matchmaker
        fightMatchmaker = new FightMatchmaker(link_token,);
        console.log("FightMatchmaker deployed at:");
        console.log(address(fightMatchmaker));

        // Initialize contracts
        address[] memory referencedContracts = new address[](2);
        referencedContracts[0] = address(fightMatchmaker);
        fightExecutor.initializeReferences(referencedContracts);
        betsVault.initializeReferences(referencedContracts);

        referencedContracts[0] = address(fightExecutor);
        referencedContracts[1] = address(betsVault);
        fightMatchmaker.initializeReferences(referencedContracts);
    }
}
