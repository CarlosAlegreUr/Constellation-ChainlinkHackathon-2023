# Fight Automation - Workflow 🌊🦭🌊

> 📘 **Note:** ℹ️ Only available in Avalanche because its cheaper and faster to use.

1️⃣ The `FightsAutomator` contract will use Chainlink Automation to check in every block the `FightsMatchmaker` state.

2️⃣ If there is someone marked as searching for fight in the `FightsMatchmaker` then `FightsAutomator` will call `FightsExecutor` to execute the fight. When the fight finishes in `FightsAutomator` after the VRF call, then `FightsAutomator` will call `FightsExecutor` to put the automated NFT looking for someone to fight again in `FightsMatchmaker`.

3️⃣ Chainlink Automation will keep checking if the automated NFTs are in a fight already and if not it will check to see if there is a fight available.

---
