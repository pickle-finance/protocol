const { ethers } = require("hardhat");
const {doGenericTest} = require("../generic-test");

const governanceAddr = "0x294aB3200ef36200db84C4128b7f1b4eec71E38a";
const timelockAddr = governanceAddr;
const strategistAddr = "0xc9a51fB9057380494262fd291aED74317332C0a2";
const controllerAddr = "0xf7B8D9f8a82a7a6dd448398aFC5c77744Bd6cb85";

const weth = "0x49d5c2bdffac6ce2bfdb6640f4f80f226bc10bab";
const globeABI = [];
const stratABI = [];  

//This is 250 WETH.e
const txnAmt = "25000000000";

describe("StrategyBenqiEth", async () => {
    const stratFactory = await ethers.getContractFactory("StrategyBenqiEth");
    const Strategy = await stratFactory.deploy(governanceAddr, strategistAddr, controllerAddr, timelockAddr);

    const globeFactory = await ethers.getContractFactory("SnowGlobeBenqiEth");
    const SnowGlobe = await globeFactory.deploy(weth, governanceAddr, timelockAddr, controllerAddr);

    doGenericTest("Weth.e", weth, SnowGlobe.address, Strategy.address, globeABI, stratABI, txnAmt);
});