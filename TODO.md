### **SUGGESTED ORDER:**

As lens and PolygonID can influence the structure of the smart contracts first we should research how their implementations work.

Then we should design the smart contracts and then all the prompts and everything according to the function parameters passed to and by smart contract's functions.

### **TODOS:**

**`Architecture`**

I've let a diagram on how I imagine the architecture so far in the docs directory.

- Redesign architechture after research.

**`Tooling Proposals`**

- Foundry for smart contract design and testing.
- Etherjs or web3js for frontend calls to blockchain services.
- As using IPFS I dont think we will a traditional backend server. In case of one I porpose express.js to manage it.
- For the front-end, nextjs or svelte.

**`Front-end`**

The website flow and design can be already deduced by the features. The logic inside each component is till to be decided but the core components (search fight button, set nft to automated fight, your NFTs display grid...) can already start to be designed and implemented.

**`Backend-SmartContracts`**

- Research how to implement with LENS.

- Research PolygonID to hide parts of your NFT details.

- Generate NFT mechanic.
    - Smart contract using Chainlink Functions (CF).
    - Deno code that calls AI image generation API.
    - Image Generation Prompt text.

- Battle mechanic.
    - Design Smart Contract using CF to manage fights and store them on IPFS (maybe).
    - Generate prompt for the battles.
    - Deno code that calls chatGPT API to generate the story.
    - Deno code to call IPFS API to store the data.

- Automated Fights.
    - Design Smart Contract of automated matchmaking mechanic.

- ENS profile registration for fight proposals to friends.

**`Impove and complete docs`**
