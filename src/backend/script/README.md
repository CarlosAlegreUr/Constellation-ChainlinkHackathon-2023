# 🏗️ HOW TO DEPLOY AND USE CONTRACTS' SCRIPTS LOCALLY 🏗️

1. Fill up the [.env](./src/backend/.env.example) secret values with your own.
   To use the contracts you will need to have an account with funds in the following chains:

2. Set your addrees value in the [Utils.sol](./src/backend/src/Utils.sol) file. It's very visible just enter the file.
3. Fund your metamask wallet with funds:

   3.1. Native coin in in Fuji-Avalanche and Sepolia-Ethereum.
   3.2. Get LINK token for future usecases, not needed in deployment though.

   - An [ETH-Faucet](https://sepoliafaucet.com/).
   - [LINK-Official-Faucet](https://faucets.chain.link/) that also provides AVL if connected to AVL chains like Fuji.

```solidity
// Utils.sol

// For now change just this one below, its marked in Utils wth 🟢.
address constant DEPLOYER = YOUR_METAMASK_ADDRESS; //🟢 <--
```

Once all values you know (but contract addresses) are set deploy the contracts with:

> 📘 **Note** ℹ️: Write, `--etherscan-api-key $S_ETHERSCAN_API_KEY_VERIFY --verify`, if you wanna verify the contracts on SEPOLIA. Not needed for proper functionality though.

> 📘 **Note 2** ℹ️: We don't use `--ffi` functionality just in case there are some shell commands that are not available in your machine. Thus you will have to manually copy 3 values in a Utils file.

```bash
source .env

forge script script/Deployment.s.sol --rpc-url $S_RPC_URL_SEPOLIA --private-key $S_SK_DEPLOYER --broadcast
```

Now in the [Utils.sol](./src/backend/src/Utils.sol) change the `DEPLOYED_SEPOLIA_COLLECTION` address value to the one you will see logged to the terminal and then run:

```bash
forge script script/Deployment.s.sol --rpc-url $AVL_NODE_PROVIDER --private-key $S_SK_DEPLOYER --broadcast
```

Now change in [Utils.sol](./src/backend/src/Utils.sol) change the `DEPLOYED_FUJI_BARRACKS` address value to the one you will se printed onto the screen and then run:

```bash
forge script script/Deployment.s.sol --sig "initSepoliaCollection()" --rpc-url $S_RPC_URL_SEPOLIA --private-key $S_SK_DEPLOYER --broadcast
```

**TODO**: if we have time automate this process with chainlink tool-kit
Now go to the [Chanlink Functions UI](https://functions.chain.link/) and create subscriptions for the Fuji testnet and for the Sepolia testnet, then change the its value in [Utils.sol](./src/backend/src/Utils.sol)

```solidity
// Utils.sol

uint64 constant ETH_SEPOLIA_FUNCS_SUBS_ID = YOUR_ID;
uint64 constant AVL_FUJI_FUNCS_SUBS_ID = YOUR_ID;
```

You must add as consumers:

- In sepolia the collection address and the FightExecutor address.
- `FightExecutor.sol` in both chains (not really in current implementation as we are mocking a DON)
