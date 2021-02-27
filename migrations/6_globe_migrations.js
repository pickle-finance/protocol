const SnowGlobe = artifacts.require("SnowGlobe");
const ControllerV4 = artifacts.require("ControllerV4");
const StrategyPngAvaxSushiLp = artifacts.require("StrategyPngAvaxSushiLp");

module.exports = async function (deployer) {
  let accounts = await web3.eth.getAccounts();
  const governance = accounts[0];
  const timelock = governance;

  let strategy = await StrategyPngAvaxSushiLp.deployed();
  let controller = await ControllerV4.deployed();
  let lp = await strategy.want();

  await deployer.deploy(SnowGlobe, lp, governance, timelock, controller.address);
};
