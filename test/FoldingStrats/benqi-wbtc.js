const { ethers } = require("hardhat");
const {doGenericTest} = require("../generic-test");

const governanceAddr = "0x294aB3200ef36200db84C4128b7f1b4eec71E38a";
const timelockAddr = governanceAddr;
const strategistAddr = "0xc9a51fB9057380494262fd291aED74317332C0a2";
const controllerAddr = "0xf7B8D9f8a82a7a6dd448398aFC5c77744Bd6cb85";

const wbtc = "0x50b7545627a5162F82A992c33b87aDc75187B218";
const globeABI = [];
const stratABI = [];  

//This is 250 WBTC.e
const txnAmt = "25000000000";

describe("StrategyBenqiWbtc", async () => {
    const stratFactory = await ethers.getContractFactory("StrategyBenqiWbtc");
    const Strategy = await stratFactory.deploy(governanceAddr, strategistAddr, controllerAddr, timelockAddr);

    const globeFactory = await ethers.getContractFactory("SnowGlobeBenqiWbtc");
    const SnowGlobe = await globeFactory.deploy(wbtc, governanceAddr, timelockAddr, controllerAddr);

    doGenericTest("Wbtc.e", wbtc, SnowGlobe.address, Strategy.address, globeABI, stratABI, txnAmt);
});