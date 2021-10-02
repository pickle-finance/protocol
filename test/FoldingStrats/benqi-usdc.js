const { ethers } = require("hardhat");
const {doGenericTest} = require("../generic-test");

const governanceAddr = "0x294aB3200ef36200db84C4128b7f1b4eec71E38a";
const timelockAddr = governanceAddr;
const strategistAddr = "0xc9a51fB9057380494262fd291aED74317332C0a2";
const controllerAddr = "0xf7B8D9f8a82a7a6dd448398aFC5c77744Bd6cb85";

const usdc = "0xa7d7079b0fead91f3e65f86e8915cb59c1a4c664";
const globeABI = [];
const stratABI = [];  

//This is 250 USDC.e
const txnAmt = "25000000000";

describe("StrategyBenqiUsdc", async () => {
    const stratFactory = await ethers.getContractFactory("StrategyBenqiUsdc");
    const Strategy = await stratFactory.deploy(governanceAddr, strategistAddr, controllerAddr, timelockAddr);

    const globeFactory = await ethers.getContractFactory("SnowGlobeBenqiUsdc");
    const SnowGlobe = await globeFactory.deploy(usdc, governanceAddr, timelockAddr, controllerAddr);

    doGenericTest("Usdc.e", usdc, SnowGlobe.address, Strategy.address, globeABI, stratABI, txnAmt);
});