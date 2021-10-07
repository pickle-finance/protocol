# Snowball Contract Testing :computer:

## Existing Tests

- Single-Asset folding strategies

## Running Tests

Tests can be ran with the following:

```bash
npx hardhat test
```

To run the tests with a persistent state, you can change networks through inspecting MetaMask or run the following:

```bash
npx hardhat node
```

...and in another terminal window:

```bash
npx hardhat test --network localhost
npx hardhat console --network localhost
```

## Tests on Deployed Contracts

Many of the existing tests are running on already deployed contracted addresses and ABI files.

If there are valid `.sol` files in the repository, but the contracts are already deployed, use the following:

```
const globeContract = await ethers.getContractAt("SnowGlobeBenqiWbtc", snowglobeAddr,  governanceSigner);
```

## Tests on New Strategies

To simulate the deployment of a new strategy, use the following:

```
const stratFactory = await ethers.getContractFactory("StrategyBenqiWbtc");
const deployedStrat = await stratFactory.deploy(governanceAddr, strategistAddr, controllerAddr, timelockAddr);
```

This code will create a factory, and through `deploy()` create an instance of that contract.
