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

---

## Deployments

In order to deploy a contract, you will first need to flatten its files. To do this, use the following:

```bash
npx hardhat flatten
```

The flattened file can be used to deploy the contract through Remix.

---

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
