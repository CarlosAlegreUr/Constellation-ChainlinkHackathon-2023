# Contribution guidelines 🚧👷⚠️
## (delete this section before dev branch is merged to main)

Just` create branches` for any work you do `that originate from` this `dev branch`.

`Never commit to main` branch, always commit to dev (development) branch.
There will be just **1 final commit to the main branch after all is coded and all docs are revised**.

---

---

# PROMPT FIGHTERS❗🤯

Do you remember when you were a kid and you were using your toys to **_`create legendary fights`_**?

Have you ever thought on **`betting and earning real money on`** fair **_`imagination battles`_** with your friends?

**`Are you too busy`** to play with your imagination like when you were a kid but **`you wish you had the time`** for it?

Well say no more, we present... **_`PROMPT FIGHTERS`_** ❗

---

## `Deep dive details` 💻

<details> <summary> Mechanics 📜 </summary>

#### Read the details of all mechanics and its reason why at [whitepaper](./docs/whitepaper.md).

#### **_`Mechanics Implemented`_**

- **Personalized NFTs** : describe your NFT as you want over a template.
- **NFT creation AI filtered** : so there are no too powerful or copyright infringement prompts.
- **Fight and bet against other NFTs**.
- **Automated Fighting** : send some funds and enjoy the fight automation.

</details>

<details> <summary> Technical details 🧑‍💻 </summary>

#### Read technical details at [docs](./docs).

#### Check the full-stack source code at [src](./src)

#### **_`Tech Used`_**

- **Chainlink VRF**: deciding fair winners
- **Chainlink CCIP**: automating process in cheaper chains. (**_Avalanche_**)
- **Chainlink Functions**: Calling APIs to generate NFTs and make them fight in amazing scenarios.
- **Chainlink Automation** (up-keeps): Automating the fight process for those who have no time to play but some time in the night to read the amazing fight stories before sleep.
- **ENS**: for easily challenging friends (on the front-end)
- **OpenAI - APIs**
- **The Graph Indexer**: for matchmaking, events tracking in website...

</details>

---

---

## `LOCAL SET-UP` 🌐-⚙️

<details> <summary> Local set-up ⚙️ </summary>

<br/>

1. **Clone the Repository**

```bash
git clone https://github.com/CarlosAlegreUr/ConstellationChainlinkHackathon2023.git
```

2. **Initialize foundry and forge**

> **Note ⚠️** We've included a `/lib` folder in the repository containing all necessary dependencies. This is due to modifications made to some CCIP files for resolving variable name conflicts with other Chainlink libraries.

**TODO, to complete**:

```bash
cd ./src/backend
foundryup
forge init
forge install --no-commit OpenZeppelin/openzeppelin-contracts
forge install --no-commit smartcontractkit/chainlink
# forge install foundry-rs/forge-std

# Chainlink ccip contracts cant be installed with forge, create in your computer a different directory
# and use npm or yarn to install them then coppy the node_modules folder inside the lib folder under the name
# of node_modules_ccip.
# Use this to isntall CCIP contracts somewhere else.
npm install @chainlink/contracts-ccip --save
```

3. **Run the Backend and forge scripts**

Deploy the contracts, but for that you will need to:

1. Fill up the [.env](./src/backend/.env.example) secret values with your own.
2. Set your addrees value in the [Utils.sol](./src/backend/src/Utils.sol) file. It's very visible just enter the file.
3. Fund your metamask wallet with funds:

   3.1. Native coin in in Fuji-Avalanche and Sepolia-Ethereum.
   3.2. Get LINK token for future usecases, not needed in deployment though.

   - An [ETH-Faucet](https://sepoliafaucet.com/).
   - [LINK-Official-Faucet](https://faucets.chain.link/) that also provides AVL if connected to AVL chains like Fuji.

```solidity
// Utils.sol

// For now change just this one below
address constant DEPLOYER = YOUR_METAMASK_ADDRESS; //🟢 <--
address constant DEPLOYED_SEPOLIA_COLLECTION = YOU WILL GET THIS VALUE FROM THE LOGS OF THE DEPLOY SCRIPT, PASTE IT HERE;
address constant DEPLOYED_FUJI_BARRACKS = YOU WILL GET THIS VALUE FROM THE LOGS OF THE DEPLOY SCRIPT, PASTE IT HERE;
```

Once all values you know (but contract addresses) are set deploy the contracts with:

> 📘 **Note** ℹ️: Write, `--etherscan-api-key $S_ETHERSCAN_API_KEY_VERIFY --verify`, if you wanna verify the contracts on SEPOLIA. Not needed for proper functionality though.

> 📘 **Note 2** ℹ️: We don't use `--ffi` functionality just in case there are some shell commands that are not available in your machine. Thus you will have to manually copy 3 values in a Utils file.

```bash
source .env

forge script script/00-Deployment.s.sol --rpc-url $S_RPC_URL_SEPOLIA --private-key $S_SK_DEPLOYER --broadcast
```

Now in the [Utils.sol](./src/backend/src/Utils.sol) change the `DEPLOYED_SEPOLIA_COLLECTION` address value to the one you will se printed onto the screen and after run:

```bash
forge script script/00-Deployment.s.sol --rpc-url $AVL_NODE_PROVIDER --private-key $S_SK_DEPLOYER --broadcast
```

Now change in [Utils.sol](./src/backend/src/Utils.sol) change the `DEPLOYED_FUJI_BARRACKS` address value to the one you will se printed onto the screen and after run:

```bash
forge script script/00-Deployment.s.sol --sig "initSepoliaCollection()" --rpc-url $S_RPC_URL_SEPOLIA --private-key $S_SK_DEPLOYER --broadcast
```

**TODO**: if we have time automate this process with chainlink tool-kit
Now go to the [Chanlink Functions UI](https://functions.chain.link/) and create subscriptions for the Fuji testnet and for the Sepolia testnet, then change the its value in [Utils.sol](./src/backend/src/Utils.sol)

```solidity
// Utils.sol

uint64 constant ETH_SEPOLIA_FUNCS_SUBS_ID = YOUR_ID;
uint64 constant AVL_FUJI_FUNCS_SUBS_ID = YOUR_ID;
```

You must add as consumers:

- In sepolia the collection address.
- `FightExecutor.sol` in both chains (not really in current implementation as we are mocking a DON)

> **Note ⚠️** Current Chainlink Functions only allows for 9s long HTTP-API calls. Our fight generation requires more than 9s thus we have mocked in the backend a node from a DON executing Chainlink Functions. Functions for NFT validation does work and is implemented interacting with the real DON.

Run the DON mock:

```bash
# Node script for mocking a listening DON.
```

4. **Running the Frontend**

All the backend is ready to so now execute the front-end
locally:

```bash
# cd to the front end directory
```

```bash
# NextJs commands etc etc...
```

---

## Run Tests 🤖

Run tests' instructions in here [tests](./src/backend/test).

---

</details>

---

## `A Message for Chainlink` 💌

During our project's development, we identified potential enhancements for Chainlink Services, particularly Chainlink Functions and Chainlink CCIP.

Key Features for Consideration:

- Library support in Deno files, especially for hashing (notably keccak256) and asymmetric encryption (ECDSA). Additionally, the addition of a library that simplifies the retrieval of logs from previous blockchain blocks would have helped a lot in optimizing our automated matchmaking and fight system while keeping costs low.

Practical Application:

- In our project, implementing hashing would enable private, unique NFT battles. Currently, NFT prompts are public, allowing duplication. Hashing prompts in Function scripts would allow on-chain storage of hashes and off-chain verification of prompt ownership, improving privacy and reducing NFT creation costs.

Challenges Encountered with CCIP:

1. Difficulty integrating CCIP with `forge`-based projects.
2. Variable clash (`i_router`) when using Functions and CCIP concurrently.
3. Non-virtual `supportsInterface()` function in `CCIPReceiver.sol`, creating inheritance conflicts in contrats that inherit different contracts using the EIP-165. (e.g., [eth-PromptFightersNFT.sol](./src/backend/src/nft-contracts/eth-PromptFightersNft.sol)).
