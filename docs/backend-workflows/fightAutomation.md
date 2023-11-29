# Fight Automation - Workflow 🌊🦭🌊

> 📘 **Note:** ℹ️ Recommended to use in `Avalanche` because its cheaper and faster to use.

1️⃣ The `FightsAutomator` contract will use Chainlink Automation to check in every block the `FightsMatchmaker` state.

2️⃣ If there is someone marked as searching for fight in the `FightsMatchmaker` then `FightsExecutor`'s `startFight()` will be called to execute the fight.

3️⃣ When the fight finishes after the VRF call, then if the player still have funds will re-enter the looking for fight state.

4️⃣ Chainlink Automation will keep checking if the automated NFTs are currently fighting and if not it will check to see if there is a fight available for them.

[Back to main workflow page](./)

---

## Drawbacks 😲

1. To make the app decentralized we need to track the pending fight requests on-chain. That is why we only allow for 5 NFTs and for 5 request to be automated on-chain at the same time. As it would become more expensevie with a greater number.

If Chanlink Functions could track previous logs thanks to a library this process wouldn't need to be stored on-chain for keeping the app decentralized. Thus making all cheaper.

> 📘 **Note:** ℹ️ In `Avalanche` the number of NFTs that can be automated can increase because it is cheper to execute.
