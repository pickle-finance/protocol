const PickleJar = artifacts.require("PickleJar");
const PickleToken = artifacts.require("PickleToken");
const StrategyPngAvaxSushiLp = artifacts.require("StrategyPngAvaxSushiLp");

module.exports = async function (deployer) {
  let accounts = await web3.eth.getAccounts();
  const governance = accounts[0];
  const strategist = accounts[0];
  const timelock = governance;

  await deployer.deploy(PickleToken);

  console.log(">>>StrategyPngAvaxSushiLp: ",StrategyPngAvaxSushiLp);
  await deployer.deploy(StrategyPngAvaxSushiLp, governance, strategist, controller.address, timelock);
  let strategy = await StrategyPngAvaxSushiLp.deployed();

  let lp = await strategy.want();

  await deployer.deploy(PickleJar, lp, governance, timelock, controller.address);
};
