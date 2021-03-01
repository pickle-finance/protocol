const ControllerV4 = artifacts.require("ControllerV4");
const StrategyPngAvaxSushiLp = artifacts.require("StrategyPngAvaxSushiLp");

module.exports = async function (deployer) {

  let controller = await ControllerV4.deployed();
  let strategy = await StrategyPngAvaxSushiLp.deployed();
  let lp = await strategy.want();

  controller.setStrategy(lp, strategy.address);
};
