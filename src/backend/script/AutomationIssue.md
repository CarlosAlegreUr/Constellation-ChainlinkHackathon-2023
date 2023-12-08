# ⚠️ SELF-REGISTRATION AUTOMATION ISSUE ⚠️

### read the readme first so you understand under which circumnstances this issue arises

I redeployed everything and only works when the Upkeep is set up from the UI, if I set up the upkeep with the code shown
above eventually appearing as Custom Logic instead of Log Trigger then it doesnt work.

Gas prices in Sepolia ETH remain more or less the same during this process, they didnt have weird spikes.

With the simulation tool I simulated the tx to the upkeep registered by my code and complains about gas limits (lets say need more than 800.000), if I simulate it with a higher gas limit (900.000) then it simulates perfectly. So I decided to register a new upkeep programatically with that new higher gas limit (900.000) so now all works and... it complains again this time demanding a higher gas limit. I simulate the transaction again but with an even greater gas (1.000.000) and the simulation deems it successfull so Im like, alright Imma register a new upkeep again with an even higher gas limit so it works and... complains again. Looks like every time is demanding higher and higher gas limits for no reason.

Interestingly enough the gas consumtiopn of the functions called in perform upkeep is constant 690.000 so a gas limit higher than that should be enough and indeed it is, whith the upkeeps registered with the UI its the case, I set the gas limit to 790.000 and it works. Here is the UI refgistered upkeep: https://automation.chain.link/sepolia/113593880572508254146564793951854302328328426573383518331617240550290028217628

So there must me something wrong with my registering code but Ive checked it multiple times and I cant find any error.

This is one of the programatically registered upkeeps: https://automation.chain.link/sepolia/105198659699106826826683314183132998151136963007704422706691727599752808214974

As you can see in this simulations with 790.000 gas limit fails but sending a simualtion with 900.000 gas succeeds:
fail -> https://dashboard.tenderly.co/CarlosAlegreUr/promptfighters/simulator/f2c76f5c-c185-45ab-bf6c-414a28d2da32
succed -> https://dashboard.tenderly.co/CarlosAlegreUr/promptfighters/simulator/b6d5ff3d-e06e-492e-93f1-00a6c9739491

So here is when I decided to use a higher gas limit in a new upkeep (limit 1.000.000 later increased to 2.000.000): https://automation.chain.link/sepolia/7602946359498938088924819702992625024381231682140795489133666556054620545125

Here are the simulations for that upkeep:
1.000.000 gas error -> https://dashboard.tenderly.co/CarlosAlegreUr/promptfighters/simulator/5f04444e-d494-418c-9d6b-9bf9f5337d09
2.000.000 gas success -> https://dashboard.tenderly.co/CarlosAlegreUr/promptfighters/simulator/1fa15d7d-64fa-4bda-8db6-d76e37495930

So I set the limit to 2.000.000 and now it fails at 2 million and succeds at 3 million. And so on. Idk whats wrong, looks like upkeep is actually calling reacting to the log but as it calls with the gasLimit it fails as for some reason it always demands a higher limit than the current one.
