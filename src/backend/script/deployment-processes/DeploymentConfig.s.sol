// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {FightMatchmaker} from "../../contracts/fight-contracts/FightMatchmaker.sol";
import {BetsVault} from "../../contracts/BetsVault.sol";
import {FightExecutor} from "../../contracts/fight-contracts/FightExecutor.sol";

import {IAutomationRegistrar} from "../../contracts/interfaces/IAutomation.sol";
import {IAutomationRegistry} from "../../contracts/interfaces/IAutomation.sol";
import {LinkTokenInterface} from "@chainlink/shared/interfaces/LinkTokenInterface.sol";

import {Script, console2} from "../../lib/forge-std/src/Script.sol";

import "../../contracts/Utils.sol";
import "../../lib/forge-std/src/console.sol";

contract DeploymentConfig is Script {
    bool public isValidConfig;

    // Chainlink Services
    LinkTokenInterface public link_token;

    address public funcs_router;
    uint64 public funcs_subsId;

    address public vrf_router;

    IAutomationRegistry public automationRegistry;
    IAutomationRegistrar public automationRegistrar;
    uint256 public automationBalanceThreshold;
    IAutomationRegistrar.RegistrationParams public automationRegistration;

    // Other contracts
    FightMatchmaker public fightMatchmaker;
    BetsVault public betsVault;
    FightExecutor public fightExecutor;

    function setUp() public virtual {
        if (block.chainid == ETH_SEPOLIA_CHAIN_ID) {
            isValidConfig = true;
            link_token = LinkTokenInterface(ETH_SEPOLIA_LINK);
            funcs_router = ETH_SEPOLIA_FUNCTIONS_ROUTER;
            funcs_subsId = ETH_SEPOLIA_FUNCS_SUBS_ID;
            vrf_router = ETH_SEPOLIA_VRF_COORDINATOR;
            automationRegistry = IAutomationRegistry(ETH_SEPOLIA_REGISTRY);
            automationRegistrar = IAutomationRegistrar(ETH_SEPOLIA_REGISTRAR);
            automationBalanceThreshold = SEPOLIA_AUTOMATION_THRESHOLD_BALANCE;
            automationRegistration = IAutomationRegistrar.RegistrationParams({
                name: "Sepolia Automation PromptFighters",
                encryptedEmail: new bytes(0),
                upkeepContract: address(0), // Set at construction time address(this)
                gasLimit: GAS_LIMIT_SEPOLIA_AUTOMATION,
                adminAddress: address(0), // Set at construction time address(this)
                triggerType: 1,
                checkData: new bytes(0),
                triggerConfig: new bytes(0), // Set at construction time, requires address(this)
                offchainConfig: new bytes(0),
                amount: LINK_AMOUNT_FOR_REGISTRATION
            });
        }

        if (block.chainid == AVL_FUJI_CHAIN_ID) {
            isValidConfig = true;
            link_token = LinkTokenInterface(AVL_FUJI_LINK);
            funcs_router = AVL_FUJI_FUNCTIONS_ROUTER;
            funcs_subsId = AVL_FUJI_FUNCS_SUBS_ID;
            vrf_router = AVL_FUJI_VRF_COORDINATOR;
            automationRegistry = IAutomationRegistry(AVL_FUJI_REGISTRY);
            automationRegistrar = IAutomationRegistrar(AVL_FUJI_REGISTRAR);
            automationBalanceThreshold = FUJI_AUTOMATION_THRESHOLD_BALANCE;
            automationRegistration = IAutomationRegistrar.RegistrationParams({
                name: "Fuji Automation PromptFighters",
                encryptedEmail: new bytes(0),
                upkeepContract: address(0), // Set at construction time address(this)
                gasLimit: GAS_LIMIT_FUJI_AUTOMATION,
                adminAddress: address(0), // Set at construction time address(this)
                triggerType: 1,
                checkData: new bytes(0),
                triggerConfig: new bytes(0), // Set at construction time, requires address(this)
                offchainConfig: new bytes(0),
                amount: LINK_AMOUNT_FOR_REGISTRATION
            });
        }

        if (isValidConfig) {
            console.log("Chain is supported, deployng...");
        } else {
            revert("Chain not supported.");
        }
    }

    function run() public virtual {}
}
