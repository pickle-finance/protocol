/* eslint-disable no-undef */
// Utilities
const Utils = require("../../utils/common-utils.js");
const { impersonates, setupCoreProtocol, depositJar } = require("../../utils/fork-utils.js");
const { governance, strategist, controller, timelock } = require("../../config");
const { send } = require("@openzeppelin/test-helpers");
const BigNumber = require("bignumber.js");
const IERC20 = artifacts.require("src/lib/erc20.sol:IERC20");

const Strategy = artifacts.require("StrategySorbettoUsdcEthLp");
const Controller = artifacts.require("src/controller-v4.sol:ControllerV4");
const PickleJar = artifacts.require("src/pickle-jar.sol:PickleJar");
const ISwapRouter = artifacts.require("ISwapRouter");

let swapRouterAddress = "0xE592427A0AEce92De3Edee1F18E0157C05861564";
let wethAddress = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2";
let usdcAddress = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48";
let wethWhale = "0x56178a0d5F301bAf6CF3e1Cd53d9863437345Bf9";

// Vanilla Mocha test. Increased compatibility with tools that integrate Mocha.
describe("Sorbetto: WETH:USDC", function() {
  let accounts;

  // external contracts
  let underlying;

  // external setup
  let underlyingWhale = "0x07379370E6900e539E5789BDD79dbF74253C290f";
  let underlyingWhales = ["0xd2be84e68c3b2ceb30dbffffbec18c21a14d7c25", "0xf2f6225962e7b1098d10f8b421b0c31936c7dcd2","0x5a14e4dc3aed9a2de038994b3ed4f3053428458a", "0xd3e0d660d8fab05b34ccb7fe7681628d9a46c675",
  "0x7bfee91193d9df2ac0bfe90191d40f23c773c060"];

  // parties in the protocol
  let farmer1;
  let alice;

  // numbers used in tests
  let farmerBalance;

  // Core protocol contracts
  let jar;
  let strategy;

  let devfund;
  let treasury;
  let swapRouter;
  let usdc;
  let weth;

  async function setupExternalContracts() {
    underlying = await IERC20.at("0xd63b340F6e9CCcF0c997c83C8d036fa53B113546");
    console.log("Fetching Underlying at: ", underlying.address);

    usdc = await IERC20.at(usdcAddress);
    console.log("Fetching USDC at: ", usdc.address);

    weth = await IERC20.at(wethAddress);
    console.log("Fetching WETH at: ", weth.address);

    swapRouter = await ISwapRouter.at(swapRouterAddress);
    console.log("Fetching SwapRouter at: ", swapRouter.address);
  }

  async function setupBalance(){
    let etherGiver = accounts[9];
    // Give whale some ether to make sure the following actions are good

    for (let i = 0; i < underlyingWhales.length; i++) {
      let whale = underlyingWhales[i];

      await send.ether(etherGiver, whale, "1" + "000000000000000000");

      console.log("underlyingWhale: ", whale);

      farmerBalance = new BigNumber(await underlying.balanceOf(whale));
      console.log("whale balance: ", farmerBalance.toFixed());
      await underlying.transfer(farmer1, farmerBalance, { from: whale });

      Utils.assertBNGt(farmerBalance, 0);
    }

    await send.ether(etherGiver, governance, "1" + "000000000000000000");

    await send.ether(etherGiver, timelock, "1" + "000000000000000000");

    await send.ether(etherGiver, alice, "1" + "000000000000000000");
  }

  before(async function() {
    accounts = await web3.eth.getAccounts();

    farmer1 = accounts[1];
    alice = wethWhale;
    devfund = accounts[8];
    treasury = accounts[7];

    // impersonate accounts
    await impersonates([governance, controller, timelock, underlyingWhale, ...underlyingWhales, wethWhale]);

    await setupExternalContracts();

    // whale send underlying to farmers
    await setupBalance();
    [jar, strategy] = await setupCoreProtocol(PickleJar, Strategy, Controller, underlying.address, governance, strategist, timelock, devfund, treasury);
  });

  describe("Sorbetto strategy earning pass", function() {
    it("Farmer should earn money", async function() {
      let farmerOldBalance = new BigNumber(await underlying.balanceOf(farmer1));

      console.log("farmerOldBalance: ", farmerOldBalance);
      await depositJar(farmer1, underlying, jar, farmerOldBalance);
      jar.earn({ from: governance });

      console.log("approve weth balance...");
      let aliceWethBalance = await weth.balanceOf(alice);
      await weth.approve(swapRouter.address, aliceWethBalance, {from: alice});

      let now = Math.floor(Date.now()/1000);
      console.log("now: ", now);

      for (let i = 0; i < 0; i ++) {
        now = now + i * 15 * 2400;
        console.log("now: ", now);

        await swapRouter.exactInputSingle([wethAddress, usdcAddress, "3000", alice, now + 120, "10000" + "00000000000000000", 0, 0], {from: alice});
  
        let aliceUSDCBalance = new BigNumber(await usdc.balanceOf(alice));
        console.log("alice usdc balance first: ", aliceUSDCBalance.toFixed());
        await usdc.approve(swapRouter.address, aliceUSDCBalance, {from: alice});

        await swapRouter.exactInputSingle([usdcAddress, wethAddress, "3000", alice, now + 120, aliceUSDCBalance, 0, 0], {from: alice});

        aliceUSDCBalance = new BigNumber(await usdc.balanceOf(alice));
        console.log("alice usdc balance second: ", aliceUSDCBalance.toFixed());
        await Utils.advanceNBlock(2400);
      }

      await strategy.harvest({ from: governance });

      console.log("farmerOldBalance: ", farmerOldBalance.toFixed());

      await jar.withdraw(jarBalance.toFixed(), { from: farmer1 });
      let farmerNewBalance = new BigNumber(await underlying.balanceOf(farmer1));
      Utils.assertBNGt(farmerNewBalance, farmerOldBalance);
      console.log("farmerNewBalance: ", farmerNewBalance.toFixed());

      console.log("earned!");
    });
  });
});
