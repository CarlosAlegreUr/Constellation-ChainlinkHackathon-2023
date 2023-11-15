# Challenge Friends - Workflow 🌊🦭🌊

**_On `Ethereum`:_**

1️⃣ The `FightsMatchmaker` will call the `ENS-NameResolver` to resolve the name of your friend, or the name of its NFT to the corresponding address.

2️⃣ Then `FightsMatchmaker` will save in the blockchains state that you are proposing your friend a fight and an event will be emitted. TheGraph will see it and your friend will receive a notification on the browser.

3️⃣ Your friend accepts the fight calling `FightsMatchmaker` and it will call `FightsExecutor` and execute the fight logic.

---

**_On `Other Chains`:_**

1️⃣ As ENS is only availabe in `Ethereum` then a CCIP call will be done to `Ethereum` to resolve the name. Once that finishes the nexts steps are the same.

---

- [Next: Workflow of fight execution](./fightExeution.md)

---
