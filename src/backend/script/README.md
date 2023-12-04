# 🏗️ USE CONTRACTS' SCRIPTS TO CHECK CHAINLINK FUNCTIONALITIES 🏗️

### This is a `walkthrough` on how to execute the contracts' code with the scripts so as to `check in action all Chainlink Services implemented`.

---

---

## Setp 1: Prepare 2 wallets and `.env` 💰💰

<details><summary> Setp 1: Prepare 2 wallets 💰💰 </summary>

1. Create and fill up an [.env](./src/backend/.env.example) file with your secret values. Check [.env.example](../.env.example).

   To use the contracts you will need to have 2 accounts with funds in the following chains:

2. Set your addreeses value in the [Utils.sol](../contracts/Utils.sol) file. It's very visible just enter the file.
3. Fund your metamask wallet with funds:

   3.1. Native coin in in Fuji-Avalanche and Sepolia-Ethereum.

   3.2. Get LINK token too.

   - An [ETH-Faucet](https://sepoliafaucet.com/).
   - [LINK-Official-Faucet](https://faucets.chain.link/) that also provides AVL if connected to AVL chains like Fuji.

```solidity
// Utils.sol

// For now change just this one below, its marked in Utils wth 🟢.
address constant DEPLOYER = YOUR_METAMASK_ADDRESS; //🟢 <--
address constant PLAYER_FOR_FIGHTS = YOUR_OTHER_ADDRESS; // 🟢
```

---

</details>

## Setp 2: Deploy the contracts 📜📜📜📜

<details><summary> Setp 2: Deploy the contracts 📜📜📜📜  </summary>

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

---

</details>

## Setp 3: Mint Nfts 👨‍👨‍👧

#### `Chainlink Functions` for validation

<details><summary> Mint Nfts 👨‍👨‍👧   </summary>

Mint 3 NFTs, 2 of them will fight and we will
send 1 to Fuji and back.

Run it 3 times for 3 NFTs.

> 📘 **Note** ℹ️: If you want them to have differnet
> prompts change the `VALID_PROMPT` value in [Utils.sol](../contract/Utils.sol). Make them short though we don't have length checkers yet. Like 3 words as much in each field.

```bash
forge script script/eth-MintNft.s.sol --rpc-url $S_RPC_URL_SEPOLIA --private-key $S_SK_DEPLOYER --broadcast
```

---

</details>

## Setp 4: Send one to `Fuji` through `CCIP` 🏣📮

#### `Chainlink CCIP`

<details><summary> Send Nft 🏣📮 </summary>

We will send NFT with ID == 3 from `Sepolia` to `Fuji`. This will take around 15min as Sepolia finalization time is 15min.

```bash
forge script script/SendNftCCIP.s.sol --rpc-url $S_RPC_URL_SEPOLIA --private-key $S_SK_DEPLOYER --broadcast
```

If you want to send it back just run after 15min have passed. It will a bit less time to come back as Fuji finalization time is shorter:

```bash
forge script script/SendNftCCIP.s.sol --rpc-url $AVL_NODE_PROVIDER --private-key $S_SK_DEPLOYER --broadcast
```

> 📘 **Note** ℹ️: Check your contract at [SnowTrace](https://testnet.snowtrace.io/) in the `Internal Transactions` section to see if the NFT has arrived. If so there will be more than 2 internal transactions.

---

</details>

## Step 5: Make them fight! 👊🤯

#### `Chainlink Functions` for fight generation and `VRF` for chosing winner

<details><summary> Make them fight! 👊🤯   </summary>

First we will request a fight with `DPELOYER` using NFT1,
then we will accept it with `PLAYER_FOR_FIGHTS` using NFT2.

> 📘 **Note** ℹ️: `DEPLOYER` owns NFT2 but the scripts transfers it to `PLAYER_FOR_FIGHTS`.

```bash
# Request a fight
forge script script/eth-Fight.s.sol --rpc-url $S_RPC_URL_SEPOLIA --private-key $S_SK_DEPLOYER --broadcast

# Accept the fight
forge script script/eth-Fight.s.sol --rpc-url $S_RPC_URL_SEPOLIA --private-key $S_SK_DEPLOYER --broadcast --etherscan-api-key $S_ETHERSCAN_API_KEY_VERIFY --verify --sig "accept()"
```

Now you should see in your `Chainlink Functions` subscription the request going on. When functions fulfill its request then you will see in your `VRF` subscripton a request pending.

>  **Note** ⚠️: If you want to see the fight in action you can change the `FIGHT_DURATION` value in [Utils.sol](../contract/Utils.sol) to 10 seconds. Then you will see the fight in action.

---

</details>
