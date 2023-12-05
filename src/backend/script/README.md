# 🏗️ USE CONTRACTS' SCRIPTS TO CHECK CHAINLINK FUNCTIONALITIES 🏗️

### This is a `walkthrough` on how to execute the contracts' code with the scripts so as to `check in action all Chainlink Services implemented`. Follow the steps in order.

---

---

## Setp 1: Prepare 2 wallets, `.env` and a functions subscription 💰💰

<details><summary> Setp 1: Prepare 2 wallets, .env and a functions subscription 💰💰 </summary>

### Settning up `.env` 🔏

1. Create and fill up an [.env](../.env.example) file with your secret values. Check [.env.example](../.env.example).

   - Get yout EtherScan API key from [here](https://etherscan.io/apis).
   - Get a Sepolia RPC_URL node provider from [here](https://www.alchemy.com/).
   - Get an OpenAI API key. (Not needed in this PoC yet)

### Setting up wallets 💰

2. Set your addresses value in the [Utils.sol](../contracts/Utils.sol) file. It's very visible just enter the file.

```solidity
// Utils.sol

// For now change just the parameters below
address constant DEPLOYER = YOUR_METAMASK_ADDRESS; //🟢 <--
address constant PLAYER_FOR_FIGHTS = YOUR_OTHER_ADDRESS; // 🟢
```

3. Fund your metamask wallet with funds. To use the contracts you will need to have 2 accounts with funds in the following chains: Sepolia and Fuji:

   3.1. Native coin in Fuji-Avalanche and Sepolia-Ethereum.

   3.2. Get LINK token too.

   - An [ETH-Faucet](https://sepoliafaucet.com/).
   - [LINK-Official-Faucet](https://faucets.chain.link/) that also provides AVL if connected to AVL chains like Fuji.

### Settning up Functions Subscriptions 🔢

1. In this example we won't fight in Fuji so you will only need a subscription
   to Sepolia --> [Chainlink Functions Sepolia Subs UI](https://functions.chain.link/)

2. Fund the subscription with at least 0.7 LINK. (Recomended 1.5 LINK)

3. Change the `ETH_SEPOLIA_FUNCS_SUBS_ID` 🟢 in the [Utils.sol](../contracts/Utils.sol) to
   the one you just got.

---

</details>
<br/>

## Setp 2: Deploy the contracts 📜📜📜📜

<details><summary> Setp 2: Deploy the contracts 📜📜📜📜  </summary>

Now its time to deploy the contracts. We will deploy the contracts in the following order:

> 📘 **Note** ℹ️: Delete `--etherscan-api-key $S_ETHERSCAN_API_KEY_VERIFY --verify` if you don't wanna verify the contracts.

> 📘 **Note 2** ℹ️: We don't use `--ffi` functionality just in case there are some shell commands that are not available in your machine. Thus you will have to manually copy 3 values in a Utils file.

```bash
cd src/backend/

source .env

forge script script/Deployment.s.sol --rpc-url $S_RPC_URL_SEPOLIA --private-key $S_SK_DEPLOYER --broadcast --etherscan-api-key $S_ETHERSCAN_API_KEY_VERIFY --verify
```

> 🚧**Note 2**⚠️ : Press save on Utils.sol every time you change a value.

Now in the [Utils.sol](../contracts/Utils.sol) change the `DEPLOYED_SEPOLIA_COLLECTION`, `SEPOLIA_FIGHT_MATCHMAKER`, `DEPLOYED_SEPOLIA_COLLECTION` and `SEPOLIA_FIGHT_EXECUTOR` addresses values to the ones you will see logged at the beggining of the command execution in the terminal. Check the contracts on [Etherscan](https://sepolia.etherscan.io/).

Now run:

```bash
forge script script/Deployment.s.sol --rpc-url $AVL_NODE_PROVIDER --private-key $S_SK_DEPLOYER --broadcast --etherscan-api-key $S_ETHERSCAN_API_KEY_VERIFY --verify
```

Now change in [Utils.sol](../contracts/Utils.sol) change the `DEPLOYED_FUJI_BARRACKS` address value to the one you will se printed onto the screen again and then run:

```bash
forge script script/Deployment.s.sol --sig "initSepoliaCollection()" --rpc-url $S_RPC_URL_SEPOLIA --private-key $S_SK_DEPLOYER --broadcast
```

**TODO**: if we have time automate this process with chainlink tool-kit

Now add a consumers from the UI in your Functions Subscription the address `DEPLOYED_SEPOLIA_COLLECTION` and `SEPOLIA_FIGHT_EXECUTOR`.

---

</details>
<br/>

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
<br/>

## Setp 4: Send one to `Fuji` through `CCIP` 🏣📮

#### `Chainlink CCIP`

<details><summary> Send Nft 🏣📮 </summary>

We will send NFT with ID == 3 from `Sepolia` to `Fuji`. This will take around 15min as Sepolia finalization time is 15min.

```bash
forge script script/SendNftCCIP.s.sol --rpc-url $S_RPC_URL_SEPOLIA --private-key $S_SK_DEPLOYER --broadcast
```

If you want to send it back just run after 15-20min have passed the following command. It will take a bit less time to come back as Fuji finalization time is shorter:

```bash
forge script script/SendNftCCIP.s.sol --rpc-url $AVL_NODE_PROVIDER --private-key $S_SK_DEPLOYER --broadcast
```

> 📘 **Note** ℹ️: Check your contract at [SnowTrace](https://testnet.snowtrace.io/) in the `Internal Transactions` section to see if the NFT has arrived. If so there will be more than 2 internal transactions.

---

</details>
<br/>

## Step 5: Make them fight! 👊🤯

#### `Chainlink Functions` for fight generation and `VRF` for chosing winner

<details><summary> Make them fight! 👊🤯   </summary>

First we will request a fight with `DPELOYER` using NFT1,
then we will accept it with `PLAYER_FOR_FIGHTS` using NFT2.

> 📘 **Note** ℹ️: `DEPLOYER` owns NFT2 but the script we are gonna run transfers it to `PLAYER_FOR_FIGHTS`.

```bash
# Request a fight
forge script script/eth-Fight.s.sol --rpc-url $S_RPC_URL_SEPOLIA --private-key $S_SK_DEPLOYER --broadcast
```

```bash
# Accept the fight
forge script script/eth-Fight.s.sol --rpc-url $S_RPC_URL_SEPOLIA --private-key $S_SK_DEPLOYER --broadcast --sig "accept()"
```

Now you should see in your `Chainlink Functions` subscription the request going on. When functions fulfill its request then you will see in your `VRF` subscripton a request pending. You should be able to see the `VRF` subscription at [https://vrf.chain.link/sepolia/YOUR_VRF_SUBS_ID](https://vrf.chain.link/sepolia/) You can consult the VRF ID in Etherscan from the `FightExecutor` contract. Or run this command in the terminal:

```bash
forge script script/CheckVrfSubsIs.s.sol --rpc-url $S_RPC_URL_SEPOLIA --private-key $S_SK_DEPLOYER
```

> 🚧 **Note** ⚠️: When we were testing all it seems like there are no nodes
> fulfilling VRF request on Sepolia as it remains pending for hours and never answered. In that case run the following command to decide a winner:

```bash
forge script script/eth-Fight.s.sol --rpc-url $S_RPC_URL_SEPOLIA --private-key $S_SK_DEPLOYER --broadcast --sig "settle()"
```

---

</details>
<br/>

## Step 6: Accept a fight with automation 🤖

#### `Chainlink Automation`

<details><summary> Use Automation to execute fights 🤖 </summary>

I couldn't test the automation code but its written in the contracts. Reasons why:

- In Sepolia testnet: One day I could deploy register automation but the other days I was getting: auto-approved disabled. I tried registring the upkeep with Chainlinks UI but it said `Pending approval...` and never changed.

- In Fuji: It was just failing with rever reason `evm error` from the `KeeperRegistryLogicB2_1.sol` contract.

Whenever we manage to create a succesfull regstration this commands should
request a fight and that fight would be later accepted by the Keeper.

```bash
# Automates nft id 2.
forge script script/eth-AutomatedFight.s.sol --rpc-url $S_RPC_URL_SEPOLIA --private-key $S_SK_PLAYER --broadcast

```

```bash
# Nft id 1 requests a fight, as nftid 2 is automated it should be accepted in the next block.
forge script script/eth-AutomatedFight.s.sol --rpc-url $S_RPC_URL_SEPOLIA --private-key $S_SK_DEPLOYER --broadcast --sig "request()"
```

---

</details>
<br/>
