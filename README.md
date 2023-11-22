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

- Personalized NFTs: describe your NFT as you want over a template.
- NFT creation AI filter: so there are not too powerful or copyright infringement prompts.
- Fight and bet against other NFTs.
- Automated Fighting: send some funds and enjoy the fight automation.

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

1. **Clone the Repository**
   Start by cloning the repository to your local machine. Run the following command:

   ```bash
   git clone [Repository URL]

   # Replace [Repository URL] with the actual URL of the repository

   ```

2. **Included Dependencies**
   We've included a `/lib` folder in the repository containing all necessary dependencies. This is due to modifications made to some CCIP files for resolving variable name conflicts with other Chainlink libraries.

3. **Running the Backend**

   ```bash
   // Bla bla
   // Fork chain bla bla
   // Maybe just interact with already deployed contracts in testnet bla bla
   ```

4. **Running the Frontend**
   To run the frontend, use Next.js commands as follows:

   ```bash
   cd [Frontend Directory]
   npm install
   npm run dev

   # Replace [Frontend Directory] with the directory name of your frontend

   ```

Please replace the placeholders (`[Repository URL]`, `[Frontend Directory]`) with the appropriate values specific to your project.

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
