
  

# Verifying Contracts

  

  

🎉🎉 Contracts can now be verified in Hardhat for Avalanche!! 🎉🎉

  

  

## Required Setup

  

1) Goto snowtrace.io and create an account

2) Goto your profile and create an API key

3) In this project's local directory, edit `.env` file to include your new key

a) e.g `SNOWTRACE_KEY=RR2IFYOUCOPYPASTANGMIPDP1D4NE1QKPZ`

4) Export environment variables (either through your .bashrc file or just straight into terminal):

a) `export HARDHAT_NETWORK=AVALANCHE`

  

_N.B. At time of writing this the `hardhat-ethers`plugin team hadn't released a snowtrace compatible version yet, so I had to do a local build and link that instead. If you don't know how to do this feel free to contact @timbotronic._

## Verifying a Single Contract

Firstly navigate to `snowtrace/args.js` and change the values here to whatever constructor arguments your contract might take in order to verify.

  

For example, when verifying the [GaugeV2](https://snowtrace.io/address/0x9817017A23B5B443d71BbAc32106658583dFfb19) contract you must provide it with the appropriate SnowGlobe Contract Address and Governance address. e.g.

```

module.exports = [

"0x7b2525a502800e496d2e656e5b1188723e547012",

"0xc9a51fb9057380494262fd291aed74317332c0a2"

];

```

  

To initiate a verify command, use the format `npx hardhat verify --constructor-args --network AVALANCHE {address name}` e.g.

```

npx hardhat verify --constructor-args snowtrace/args.js --network AVALANCHE 0x0Ec726BF3FF6CBf58c9f300d86F5fAd149a52039

```

  

Hopefully everything has worked and you will get a message in your terminal screen confirming success. Congratulations! 🎊

  

## Verifying Lots of Contracts at once

If you are wanting to batch together lots of verify commands at once, we have a script that allows you to batch lots of commands together. It's not perfect, and it runs very slowly - so you may want to make a sandwich after setting it off (probably best that you test it with a single first though!)

Same drill as before, we need to provide hardhat with the contract `address` to verify and `args` to supply as constructor parameters.

In the `snowtrace/verify-script.js` file add however many contracts you want to verify in a batch with the format:
```
{
	address: "Contract Address",
	args: ["Arg1","Arg2","Arg3",..],
}
```

Once you can created a list of objects in `const contracts` you can initiate the batch verify with:
```
node snowtrace/verify-script.js
```

Again you should see each contract being verified with confirmation. If so, congratulations!!! 🎊🎊


## Troubleshooting

### It recompiles all contracts between tasks
This is unfortunately a `hardhat-etherscan` bug which will hopefully get fixed in later versions. If you think this is a bug with this code, please feel free to reach out!

### NomicLabsHardhatPluginError: An etherscan endpoint could not be found for this network. ChainID: 43114. The selected network is AVALANCHE.
This means your `hardhat-etherscan` plugin doesn't have snowtrace enabled. Locally install a fixed version and connect it to this project with the `yarn link` functionality.

###  NomicLabsHardhatPluginError: The selected network is hardhat. Please select a network supported by Etherscan.

You need to export the environment variable to specify hardhat to use the avalanche config. You do have avalanche config in your hardhat config right? 

### FATAL ERROR: Ineffective mark-compacts near heap limit Allocation failed - JavaScript heap out of memory

Snowball has a LOT of contracts, and this can cause hardhat memory issues. Run something like this to allow it to run:
```
export NODE_OPTIONS=--max_old_space_size=4096
```