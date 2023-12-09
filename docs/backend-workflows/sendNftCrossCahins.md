# Send NFT Cross-Chain - Workflow 🌊🦭🌊

1️⃣ You will interact with contrats that inherit from the abstract contract `CcipNftBdrige`.

2️⃣ Then the `sendNft()` function will be called.

3️⃣ After the block finalization time has passed the nft will be received in the other chain
eventually triggering `_ccipReceive()` function.

3️⃣ Notice different blockchains have different finalization times. Ethereum -> OtherEvm chain
takes around 15-20min.

---

- [Next: Main Menu](./)

---
