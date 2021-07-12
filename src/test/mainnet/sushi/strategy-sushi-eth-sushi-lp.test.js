/* eslint-disable no-undef */
// Utilities
const Utils = require("../../utils/common-utils.js");
const { impersonates, setupCoreProtocol, depositJar } = require("../../utils/fork-utils.js");
const { governance, strategist, controller, timelock } = require("../../config");
const { send } = require("@openzeppelin/test-helpers");
const BigNumber = require("bignumber.js");
const IERC20 = artifacts.require("src/lib/erc20.sol:IERC20");

//const Strategy = artifacts.require("");
const Strategy = artifacts.require("StrategySushiEthSushiLp");
const Controller = artifacts.require("src/controller-v4.sol:ControllerV4");
const PickleJar = artifacts.require("PickleJar");

// Vanilla Mocha test. Increased compatibility with tools that integrate Mocha.
describe("Sushi: SUSHI:WETH", function() {
  let accounts;

  // external contracts
  let underlying;

  // external setup
  let underlyingWhale = "0x88B521167CC35A22B51EA5caDD7DbCd4cc2Cbc57";

  // parties in the protocol
  let farmer1;

  // numbers used in tests
  let farmerBalance;

  // Core protocol contracts
  let jar;
  let strategy;

  let devfund;
  let treasury;

  async function setupExternalContracts() {
    underlying = await IERC20.at("0x795065dCc9f64b5614C407a6EFDC400DA6221FB0");
    console.log("Fetching Underlying at: ", underlying.address);
  }

  async function setupBalance(){
    let etherGiver = accounts[9];
    // Give whale some ether to make sure the following actions are good
    await send.ether(etherGiver, underlyingWhale, "1" + "000000000000000000");

    await send.ether(etherGiver, governance, "1" + "000000000000000000");

    await send.ether(etherGiver, timelock, "1" + "000000000000000000");

    console.log("underlyingWhale: ", underlyingWhale);

    farmerBalance = await underlying.balanceOf(underlyingWhale);
    await underlying.transfer(farmer1, farmerBalance, { from: underlyingWhale });

    Utils.assertBNGt(farmerBalance, 0);
  }

  before(async function() {
    accounts = await web3.eth.getAccounts();

    farmer1 = accounts[1];
    devfund = accounts[8];
    treasury = accounts[7];

    // impersonate accounts
    await impersonates([governance, controller, timelock, underlyingWhale]);

    await setupExternalContracts();

    // whale send underlying to farmers
    await setupBalance();
    [jar, strategy] = await setupCoreProtocol(PickleJar, Strategy, Controller, underlying.address, governance, strategist, timelock, devfund, treasury);
  });

  describe("Happy path", function() {
    it("Farmer should earn money", async function() {
      let farmerOldBalance = new BigNumber(await underlying.balanceOf(farmer1));
      await depositJar(farmer1, underlying, jar, farmerBalance);
      jar.earn({ from: governance });

      let hours = 10;
      let blocksPerHour = 2400;
      for (let i = 0; i < hours; i++) {
        console.log("loop ", i);
        await strategy.harvest({ from: governance });
        await Utils.advanceNBlock(blocksPerHour);
      }

      const jarBalance = new BigNumber(await jar.balanceOf(farmer1));
      console.log("jarBalance: ", jarBalance.toFixed());

      await jar.withdraw(jarBalance.toFixed(), { from: farmer1 });
      let farmerNewBalance = new BigNumber(await underlying.balanceOf(farmer1));
      Utils.assertBNGt(farmerNewBalance, farmerOldBalance);

      apr = (farmerNewBalance.toFixed()/farmerOldBalance.toFixed()-1)*(24/(blocksPerHour*hours/1200))*365;
      apy = ((farmerNewBalance.toFixed()/farmerOldBalance.toFixed()-1)*(24/(blocksPerHour*hours/1200))+1)**365;

      console.log("earned!");
      console.log("APR:", apr*100, "%");
      console.log("APY:", (apy-1)*100, "%");
    });
  });
});
