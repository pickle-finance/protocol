## Testing Smart Contracts

So far we only have testing for the Strategies for the single asset folding strategies. They can be run with the following

```bash
npx hardhat test
```

To persist the state you can inspect on metamask or via the console you can run:

```
npx hardhat node

// on new terminal
npx hardhat test --network localhost
npx hardhat console --network localhost
```

## Testing existing strategies without using the ABI
Many tests written are using already deployed contract addresses and ABI files. 

If there are valid `.sol` files in the repo, but are deployed already you can instead run:
```
const globeContract = await ethers.getContractAt("SnowGlobeBenqiWbtc", snowglobeAddr,  governanceSigner);
```

## Testing new strategies

If you want to simulate deploying a new strategy, you can instead run these which will first create a factory, and then use the deploy task to deploy and istance of that contract:
```
const stratFactory = await ethers.getContractFactory("StrategyBenqiWbtc");
const deployedStrat = await stratFactory.deploy(governanceAddr, strategistAddr, controllerAddr, timelockAddr);
```