# Matchmaking - Workflow 🌊🦭🌊

1️⃣ User sends a fight request trhough the website.

2️⃣ That request will arrive to the `FightsMatchmaker` contract and will emit an event with the users request to fight.

3️⃣ `TheGraph` will index this request and other users will be able to see it on the website. Then they will accept the request if they wanna fight.

4️⃣ With the accept fight transaction the matchamking process is over. The fight automatically starts via chainlink functions when the `FightsMatchmaker` calls the `FightsExecutor` contract.

- [Next: Challenge a friend](./challengeFriends.md)

- [Next: Workflow of fight execution](./fightExeution.md)

---

## Drawbacks 😢

1. The search for fight transaction, as we don't use a backend, costs money due to regstering in the blockchain's state that the player is looking for a fight.

2. The accept transaction, as it triggers chainlink functions, its more expensive to call. Giving a bigger lose by default to the accepting address. This can be solved by forcing the requesting addres to send some money with the request transaction so as to when the fight is accepted, that money is sent back to the acceptor and thus both players share the cost of the fight booting.
   > 📘 **NOTE:** ℹ️ Due to time constrains in the hackathon we might not implement this.
