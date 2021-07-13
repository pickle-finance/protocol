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
let weth = "0xc02aaa39b223fe8d0a0e5c4f27ead9083c756cc2";
let usdcAddress = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48";

// Vanilla Mocha test. Increased compatibility with tools that integrate Mocha.
describe("Sorbetto: WETH:USDC", function() {
  let accounts;

  // external contracts
  let underlying;

  // external setup
  let underlyingWhale = "0x07379370E6900e539E5789BDD79dbF74253C290f";

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

  async function setupExternalContracts() {
    underlying = await IERC20.at("0xd63b340F6e9CCcF0c997c83C8d036fa53B113546");
    console.log("Fetching Underlying at: ", underlying.address);

    usdc = await IERC20.at(usdcAddress);
    console.log("Fetching USDC at: ", usdc.address);

    swapRouter = await ISwapRouter.at(swapRouterAddress);
    console.log("Fetching USDC at: ", swapRouter.address);
  }

  async function setupBalance(){
    let etherGiver = accounts[9];
    // Give whale some ether to make sure the following actions are good
    await send.ether(etherGiver, underlyingWhale, "1" + "000000000000000000");

    await send.ether(etherGiver, governance, "1" + "000000000000000000");

    await send.ether(etherGiver, timelock, "1" + "000000000000000000");

    console.log("underlyingWhale: ", underlyingWhale);

    farmerBalance = new BigNumber(await underlying.balanceOf(underlyingWhale));
    console.log("whale balance: ", farmerBalance.toFixed());
    await underlying.transfer(farmer1, farmerBalance, { from: underlyingWhale });

    Utils.assertBNGt(farmerBalance, 0);
  }

  before(async function() {
    accounts = await web3.eth.getAccounts();

    farmer1 = accounts[1];
    alice = accounts[2];
    devfund = accounts[8];
    treasury = accounts[7];

    // impersonate accounts
    await impersonates([governance, controller, timelock, underlyingWhale]);

    await setupExternalContracts();

    // whale send underlying to farmers
    await setupBalance();
    [jar, strategy] = await setupCoreProtocol(PickleJar, Strategy, Controller, underlying.address, governance, strategist, timelock, devfund, treasury);
  });

  describe("Sorbetto strategy earning pass", function() {
    it("Farmer should earn money", async function() {
      let farmerOldBalance = new BigNumber(await underlying.balanceOf(farmer1));
      await depositJar(farmer1, underlying, jar, farmerBalance);

      let now = Math.floor(Date.now()/1000);
      console.log("now: ", now);

      await swapRouter.exactInputSingle([weth, usdcAddress, "3000", alice, now + 120, "1" + "00000000000000000", 0, 0], {value: "1" + "00000000000000000", from: alice});

      let aliceUSDCBalance = new BigNumber(await usdc.balanceOf(alice));

      console.log("alice usdc balance: ", aliceUSDCBalance.toFixed());

      await strategy.harvest({ from: governance });

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
