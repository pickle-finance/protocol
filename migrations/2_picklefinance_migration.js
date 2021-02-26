const PickleJar = artifacts.require("PickleJar");
const ControllerV4 = artifacts.require("ControllerV4");
const MasterChef = artifacts.require("MasterChef");
const PickleToken = artifacts.require("PickleToken");
const StrategyPngAvaxSushiLp = artifacts.require("StrategyPngAvaxSushiLp");

module.exports = async function (deployer) {
  let accounts = await web3.eth.getAccounts();
  const governance = accounts[0];
  const strategist = accounts[0];
  const devpool = accounts[0];
  const treasury = accounts[0];
  const timelock = governance;

  let startblock = await web3.eth.getBlockNumber();
  let endblock = 200000000;
  const pickleperblock = 1000;


  await deployer.deploy(PickleToken);
  let pickle = await PickleToken.deployed();

  await deployer.deploy(MasterChef, pickle.address, devpool, pickleperblock, startblock, endblock);
  let masterchef = await MasterChef.deployed();

  await deployer.deploy(ControllerV4, governance, strategist, timelock, devpool, treasury);
  let controller = await ControllerV4.deployed();

  await deployer.deploy(StrategyPngAvaxSushiLp, governance, strategist, controller.address, timelock);
  let strategy = await StrategyPngAvaxSushiLp.deployed();

  let lp = await strategy.want();

  await deployer.deploy(PickleJar, lp, governance, timelock, controller.address);
};
