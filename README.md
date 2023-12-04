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

2. **Initialize foundry, forge and dependencies**

```bash
cd ./ConstellationChainlinkHackathon2023/src/backend
foundryup
forge init --force --no-commit
forge install --no-commit OpenZeppelin/openzeppelin-contracts@932fddf69a699a9a80fd2396fd1a2ab91cdda123

forge install --no-commit smartcontractkit/chainlink@cdb0c6a6089d3a69dd09a9b0a9fbdd070eaeb442

# Chainlink ccip contracts cant be installed with forge

# Use this to isntall CCIP contracts in "./src/backend" (you should already be here)

# Just leave everythin empty and press enter
npm init
npm install @chainlink/contracts-ccip --save

# Change the name to node_modules_ccip
mv ./node_modules ./node_modules_ccip

# Move it inside the /lib diretory
mv ./node_modules_ccip ./lib
# ⚠️ Wait until all has moved correctly
# ⚠️ node_modules_ccip should be now ONLY inside ./lib
# Notice ℹ️ you can remove package.jon and package-lock.json
# if you want.
```

**_The /lib directory should now look like this:_**

<img src="./repo-images/lib-example.png">

<br/>

3. **Prepare Wallet to use the contracts**

To use the contracts you will need to have an account with funds in the following chains:

2. Set your addrees value in the [Utils.sol](./src/backend/src/Utils.sol) file. It's very visible just enter the file.
3. Fund your metamask wallet with funds:

   3.1. Native coin in in Fuji-Avalanche and Sepolia-Ethereum.
   3.2. Get LINK token on both chains.

   - An [ETH-Faucet](https://sepoliafaucet.com/).
   - [LINK-Official-Faucet](https://faucets.chain.link/) that also provides AVL if connected to AVL chains like Fuji.

```solidity
// Utils.sol

// For now change just this one below, its marked in Utils wth 🟢.
address constant DEPLOYER = YOUR_METAMASK_ADDRESS; //🟢 <--
```

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

## Run Scripts locally and Deploy contracts 🏗️🏛️

Run scripts' instructions in here: [scripts](./src/backend/script).

---

## Run Tests 🤖

Run tests' instructions in here: [tests](./src/backend/test).

---

</details>

---

## `A Message for Chainlink` 💌

During our project's development, we identified potential enhancements for Chainlink Services, particularly Chainlink Functions and Chainlink CCIP.

#### Key Features for Consideration:

1. Library support in Deno files, especially for hashing (notably keccak256) and asymmetric encryption (ECDSA). Additionally, the addition of a library that simplifies the retrieval of logs from previous blocks would have helped a lot in optimizing and scaling the automated matchmaking and fight system while keeping costs low.

   Practical Application:

   - In our project, implementing hashing would enable private, unique NFT prompts. Currently, NFT prompts are public, allowing duplication. Hashing prompts in Function scripts would allow on-chain storage of hashes and off-chain verification of prompt ownership by the DON, improving privacy and reducing NFT creation costs.

2. Allow for longer HTTP-API calls. AIs that generate images or a bit long outputs like stores take more than the current limit of 9s. Thus we had to mock in Funtions a response simulating an actual AI-API call. Regardless of this the code that would be used if this restriction didn't exist is added in the project.

3. A tool for simulating DONs reponses in local with forked Chainlink contracts would be very helpful for easier debugging and testing.
   We don't know if this tool already exists, but we think it would be very useful.

#### Challenges and errors encountered:

With **_`CCIP`_**:

1. Difficulty integrating CCIP with `forge`-based projects.
2. Variable clash (`i_router`) when using Functions and CCIP concurrently.
3. Non-virtual `supportsInterface()` function in `CCIPReceiver.sol`, creating inheritance conflicts in contrats that inherit different contracts using the EIP-165. (e.g., [eth-PromptFightersNFT.sol](./src/backend/contracts/nft-contracts/eth-PromptFightersNft.sol)).

With **`Automation`**:

1. Registration is only working on Sepolia. On Fuji the
   code reverts due to `evm Error` in the deployed `KeeperRegistryLogicB2_1`. On Mumbai it doen't run.

2. Additionally there is an error in your docs for Fuji, registry and registrar are the same address. We tried
   to find the real registrar address on Snowflake and we think we did but the error still persists. This is the address we used: `0x5Cb7B29e621810Ce9a04Bee137F8427935795d00`.

For this reasons automation code of our project only wokrs
on Sepolia.

With **`VRF`**:

1. For some reason nodes in Sepolia don't respond to VRF
   requests. Thus in this project we allowed the DEPLOYER to finish fights too in case VRF doesn't respond.
