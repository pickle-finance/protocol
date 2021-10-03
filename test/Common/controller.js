// Don't need this template until controller V5


// const hre = require("hardhat");
// const { ethers, network } = require("hardhat");
// const chai = require("chai");
// const { BigNumber } = require("@ethersproject/bignumber");
// const {increaseTime, overwriteTokenAmount, increaseBlock} = require("../utils/helpers");
// const { expect } = chai;
// const {setupSigners} = require("../utils/actors");


// describe("ControllerV4", async () => {

//     const walletAddr = process.env.WALLET_ADDR;
//     let controllerContract;
//     let governanceSigner, strategistSigner, controllerSigner, timelockSigner;

//     before( async () => {
//         await network.provider.send('hardhat_impersonateAccount', [walletAddr]);
//         walletSigner = ethers.provider.getSigner(walletAddr);
//         [timelockSigner,strategistSigner,controllerSigner,governanceSigner] = await setupSigners();
//         controllerContract = await ethers.getContractAt("ControllerV4", await controllerSigner.getAddress(),  governanceSigner);
//     });


// });