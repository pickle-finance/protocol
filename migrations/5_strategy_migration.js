const ControllerV4 = artifacts.require("ControllerV4");
const StrategyPngAvaxSushiLp = artifacts.require("StrategyPngAvaxSushiLp");

module.exports = async function (deployer) {
  let accounts = await web3.eth.getAccounts();
  const governance = accounts[0];
  const strategist = accounts[0];
  const timelock = governance;

  let controller = await ControllerV4.deployed();

  await deployer.deploy(StrategyPngAvaxSushiLp, governance, strategist, controller.address, timelock);
};
