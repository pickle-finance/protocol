/* eslint-disable no-undef */
const hre = require("hardhat");
const { ethers } = require("hardhat");
const chai = require("chai");
const { expect } = chai;

describe("TraderJoe", async () => {
  const gaugeProxyV1ABI = [{"type":"constructor","stateMutability":"nonpayable","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"contract IceQueen"}],"name":"MASTER","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"contract IERC20"}],"name":"SNOWBALL","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"contract IERC20"}],"name":"SNOWCONE","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"contract IERC20"}],"name":"TOKEN","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"acceptGovernance","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"addGauge","inputs":[{"type":"address","name":"_token","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"collect","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"deposit","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"distribute","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"gauges","inputs":[{"type":"address","name":"","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"getGauge","inputs":[{"type":"address","name":"_token","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"governance","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"length","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"pendingGovernance","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"pid","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"poke","inputs":[{"type":"address","name":"_owner","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"reset","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setGovernance","inputs":[{"type":"address","name":"_governance","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setPID","inputs":[{"type":"uint256","name":"_pid","internalType":"uint256"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"tokenVote","inputs":[{"type":"address","name":"","internalType":"address"},{"type":"uint256","name":"","internalType":"uint256"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address[]","name":"","internalType":"address[]"}],"name":"tokens","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"totalWeight","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"usedWeights","inputs":[{"type":"address","name":"","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"vote","inputs":[{"type":"address[]","name":"_tokenVote","internalType":"address[]"},{"type":"uint256[]","name":"_weights","internalType":"uint256[]"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"votes","inputs":[{"type":"address","name":"","internalType":"address"},{"type":"address","name":"","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"weights","inputs":[{"type":"address","name":"","internalType":"address"}]}];
  
  const governanceAddr = "0x294aB3200ef36200db84C4128b7f1b4eec71E38a";
  const iceQueenAddr = "0xB12531a2d758c7a8BF09f44FC88E646E1BF9D375";
  const userAddr = "0xdbc195a0ED72c0B059f8906e97a90636d2B6409F";

  const pngAvaxAaveE = "0x7F8E7a8Bd63A113B202AE905877918Fb9cA13091";
  const snobAddr = "0xC38f41A296A4493Ff429F1238e030924A1542e50";

  const s4D = "0xB91124eCEF333f17354ADD2A8b944C76979fE3EC";

  const gaugeProxyV1addr = "0xFc371bA1E7874Ad893408D7B581F3c8471F03D2C";
  
  before( async () => {

    await hre.network.provider.request({
      method: "hardhat_impersonateAccount",
      params: [governanceAddr],
    });
  
    const governanceSigner = ethers.provider.getSigner(governanceAddr);
    const userSigner = ethers.provider.getSigner(userAddr);
    const iceQueen = await ethers.getContractAt(
      "contracts/yield-farming/icequeen.sol:IceQueen",
      iceQueenAddr,
      governanceSigner
    );
    iceQueen.connect(governanceSigner);
  });

  beforeEach( async () => {
    console.log('-- Connect to GaugeProxyV1 --');
    const gaugeProxyV1 = new ethers.Contract(gaugeProxyV1addr, gaugeProxyV1ABI, governanceSigner);
  
    console.log("-- Deploying GaugeProxyV2 contract --");
    const GaugeProxyV2 = await hre.ethers.getContractFactory("GaugeProxyV2");
    const gaugeProxyV2 = await GaugeProxyV2.deploy();
    await gaugeProxyV2.deployed();
  
    const mSNOWCONESAddr = await gaugeProxyV2.TOKEN();
    console.log(`GaugeProxy deployed at ${gaugeProxyV2.address}`);
  
    console.log("-- Adding mSNOWCONES to iceQueen --");
    let populatedTx;
    populatedTx = await iceQueen.populateTransaction.add(
      5000000,
      mSNOWCONESAddr,
      false,
      { gasLimit: 9000000 }
    );
    await governanceSigner.sendTransaction(populatedTx);
  });
  
  it("should paginate distribution", async () => {
    expect(await strategyJoeAvaxEth.deployed()).not.to.equal(0);
  });

  it("should have the strategy approved in the controller", async () => {
    expect(await controller.approvedStrategies(joeAvaxEthLPAddress, strategyJoeAvaxEthAddress)).not.to.equal(0);
  });

  it("should have the strategy set in the controller", async () => {
    expect(await controller.strategies(joeAvaxEthLPAddress)).to.equal(strategyJoeAvaxEthAddress);
  });

  it("should have a value greater than zero in the strategy", async () => {
    expect(initial_balance).not.to.equal(0);
  });

  it("should be strategist for strategy", async () => {
    expect(await strategyJoeAvaxEth.strategist()).to.equal(ownerAddress);
  });

  it("should be able to harvest", async () => {
    /* Increase Time */
    await hre.network.provider.send("evm_increaseTime", [86400]);
    await hre.network.provider.send("evm_mine");
    let strategy = new ethers.Contract(strategyJoeAvaxEthAddress, strategyJoeAvaxEthABI, owner);
    await strategy.harvest();
    let new_balance = await strategy.balanceOf();
    expect(new_balance).to.be.above(initial_balance);

    expect().not.to.equal(0);
  });

  it("should be able to withdraw all", async () => {
    expect(await snowGlobeJoeAvaxEth.withdrawAll()).not.to.equal(0);
  });
});