<div align="center">
<h1>Snowball - Protocol 🎣 </h1>

<p>This repository includes Solidity files for Snowball's underlying smart contracts.</p>
</div>

---

## Getting Started

We are utilizing Hardhat to compile and test our smart contracts.

In order to create a reproducible environment, please use Hardhat locally when setting up your project. This will avoid any possible version conflicts.

To install all our dependencies, run the following:

```bash
npm i
```

To run any local hardhat scripts, use `npx hardhat` (more details will follow).

---

## Testing

By default, tests are executed on a fork of Avalanche's Mainnet C-Chain.

To create local accounts for testing, create a copy of the .env file containing your addresses/keys:

```bash
cp .env.example .env
```

If you run into any memory-related errors, use the following to allocate more heap space to your node process:

```
export NODE_OPTIONS=--max_old_space_size=4096
```

To compile and run all testing scripts available in the `/test/` directory, use the following:

```bash
npx hardhat test
```

> To learn more about the tests available and how to run them, click [here](test/README.md).

To find the slot of a token, install and run the slot20 tool (https://github.com/kendricktan/slot20):

```
npm i slot20
```
In another terminal, start a hardhat fork:

```
npx hardhat node --fork https://api.avax.network/ext/bc/C/rpc
```

then, run:
```
slot20 balanceOf <token address> <token holder>
```

---

## Deployments

In order to deploy a contract, you will first need to flatten its files. To do this, use the following:

```bash
npx hardhat flatten
```

The flattened file can be used to deploy the contract through Remix.

---

## Naming Convention

“Programs must be written for people to read, and only incidentally for machines to execute.”
- Harold Abelson, Structure and Interpretation of Computer Programs

It is important that we come to a common understanding and practice when it comes to the naming convention of our code base.

Although it is the case that human readability takes precedence, we should also weigh carefully the effects that naming will have on our operational scripts and automated processes.

The smart contract code has recently begun to diverge from our historical naming convention. In order to combat this I'd like to make some notes on naming, especially with regard to our strategies.

# Strategy names:
Strategy names should include reference to the platform and the tokens affected.

For example StrategyPngAvaxPngLp.
Let's break this down:

Strategy - this is the type of contract that it is
Png - this is the platform it is built upon
Avax this is the primary token
Png this is the secondary token
Lp the two tokens are bound together in a Liquidity Pool.

It's worth noting that the strategies, as well as all other contracts, are written in UpperCamelCase format. This is in keeping with standard Object Oriented fashion since the contracts are Classes and follow standard Inheretance.

# Function names

Functions within the contracts should be written in lowerCamelCase. This is again in keeping with standard software engineering practices, both within and outside of Object Oriented Programing. 

Functions that are private, that is, functions that can only be called by the parent class, should be prepended by an underscore '_' like so _lowerCamelcase.

# Variable names
Variables, should only contain lowercase letters, words separated by an underscore '_' (this is often called snake_case), unless the variable is representing an instantiated object of a class (contract or interface), in which case, it can follow the UpperCamelCase form used by objects.

# Parameter names
In order to match the convention elsewhere in our codebase, parameters should follow standard variable naming convention, except in the case that the parameter represents a class variable (field) that is being overwritten by the function (such as in a constructor). In this case, the parameter name should also be prepended by an underscore '_' like so _snake_case. 


## Contracts

### Main Snowball Contracts
Name | Address
--- | ---
SNOB | 0xc38f41a296a4493ff429f1238e030924a1542e50
xSNOB | 0x83952E7ab4aca74ca96217D6F8f7591BEaD6D64E
Governance | 0xfdCcf6D49A29f435E509DFFAAFDecB0ADD93f8C0
Treasury | 0x294aB3200ef36200db84C4128b7f1b4eec71E38a
Council | 0x028933a66DD0cCC239a3d5c2243b2d96672f11F5
Payroll | 0x05faF04e3416e40Af70ecA1deEfe2E8B6feC3703
Proposal 3 Funds | 0x5df42ace37bA4AceB1f3465Aad9bbAcaA238D652
Controller V1 | 0xf7B8D9f8a82a7a6dd448398aFC5c77744Bd6cb85
Controller V2 | 0xacc69deef119ab5bbf14e6aaf0536eafb3d6e046
GaugeProxy V2 | 0x215D5eDEb6A6a3f84AE9d72962FEaCCdF815BF27

> A more comprehensive list of all StableVault, Snowglobe contracts along with their respective gauges and strategies can be found in our documentation [here](https://snowballs.gitbook.io/snowball-docs/resources/smart-contracts).

---

## Contributors ✨

<!-- prettier-ignore-start -->
<!-- markdownlint-disable -->
<table>
  <tr>
    <td align="center"><a href="https://github.com/jomarip"><img src="https://avatars.githubusercontent.com/u/3376497?v=4" width="100px;" alt=""/><br /><sub><b>Jomari</b></sub></a></td>
    <td align="center"><a href="https://github.com/bigwampa"><img src="https://avatars.githubusercontent.com/u/79389347?v=4" width="100px;" alt=""/><br /><sub><b>Big.Wampa</b></sub></a></td>
    <td align="center"><a href="https://github.com/AbigailTCameron"><img src="https://avatars.githubusercontent.com/u/75511255?v=4" width="100px;" alt=""/><br /><sub><b>Abigail</b></sub></a></td>
    <td align="center"><a href="https://github.com/timbotro"><img src="https://avatars.githubusercontent.com/u/89510251?v=4" width="100px;" alt=""/><br /><sub><b>Timbotronic</b></sub></a></td>
    <td align="center"><a href="https://github.com/theabominablesasquatch"><img src="https://avatars.githubusercontent.com/u/79382337?v=4" width="100px;" alt=""/><br /><sub><b>Abominable Sasquatch</b></sub></a></td>
    <td align="center"><a href="https://github.com/kmcintyre"><img src="https://avatars.githubusercontent.com/u/1017886?v=4" width="100px;" alt=""/><br /><sub><b>Kevin</b></sub></a></td>
    <td align="center"><a href="https://github.com/Jonasslv"><img src="https://avatars.githubusercontent.com/u/20801365?v=4" width="100px;" alt=""/><br /><sub><b>Jonas</b></sub></a></td>
  </tr>
</table>

<!-- markdownlint-restore -->
<!-- prettier-ignore-end -->
