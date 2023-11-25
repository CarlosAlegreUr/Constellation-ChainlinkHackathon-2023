# TODO (update quantities, commands, texts):

# Unit-test 👶

The unit-test cover simple test for the basic functionalities that don't utilize any
Chainlink DON services.

To run them:

```bash
cd ./src/backend
forge forge test --contracts test/unit-test/
```

# Integration-test 🧑

Test in the testnets for testing the
Chainlink Services interacting with DONs.

To run them:

1. fund your `DEPLOYER_ADDRESS` with 20 LINK and 1 ETH in `Sepolia` and 1 ETH in `Fuji`.

(**TODO**: add links to faucets)

2. Execute:

```bash
forge test
```
