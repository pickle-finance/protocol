const SnowGlobe = artifacts.require("SnowGlobe");
const ControllerV4 = artifacts.require("ControllerV4");
const StrategyPngAvaxSushiLp = artifacts.require("StrategyPngAvaxSushiLp");

module.exports = async function () {

  let controller = await ControllerV4.deployed();
  let strategy = await StrategyPngAvaxSushiLp.deployed();
  let globe = await SnowGlobe.deployed();
  let lp = await strategy.want();

  controller.setGlobe(lp, globe.address).then(() => {
    controller.approveStrategy(lp, strategy.address).then(() => {
      controller.setStrategy(lp, strategy.address);
    })
  })
};
