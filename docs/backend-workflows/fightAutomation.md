# Fight Automation - Workflow 🌊🦭🌊

> 📘 **Note:** ℹ️ Recommended to use in `Avalanche` because its cheaper and faster to use.

1️⃣ The `FightsAutomator` contract will use Chainlink Automation to check in every block the `FightsMatchmaker` state.

2️⃣ If there is someone marked as searching for fight in the `FightsMatchmaker` then `FightsExecutor`'s `startFight()` will be called to execute the fight. (via event-log trigger)

3️⃣ When the fight finishes after the VRF call, then if the player still have funds will re-enter the looking for fight state.

4️⃣ Chainlink Automation will keep checking if the automated NFTs are currently fighting and if not it will check to see if there is a fight available for them.

[Next: Sending NFTs cross-chains](./sendNftCrossCahins.md)

---

## Drawbacks 😲

1. To make the app decentralized we need to track the pending fight requests on-chain. That is why we only allowed for 1 NFT to be automated on-chain at the same time. As it would become more expensevie with a greater numbers.

If Chanlink Functions could track previous logs thanks to a library this process wouldn't need to be stored on-chain as matchmaking could be done via logs. Thus making all cheaper.
