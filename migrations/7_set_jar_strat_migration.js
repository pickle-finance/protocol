const PickleJar = artifacts.require("PickleJar");
const ControllerV4 = artifacts.require("ControllerV4");
const StrategyPngAvaxSushiLp = artifacts.require("StrategyPngAvaxSushiLp");

module.exports = async function (deployer) {
  let accounts = await web3.eth.getAccounts();
  const governance = accounts[0];


  let controller = await ControllerV4.deployed();
  let strategy = await StrategyPngAvaxSushiLp.deployed();
  let jar = await PickleJar.deployed();
  let lp = await strategy.want();

  controller.setJar(lp, jar.address).then(() => {
    controller.approveStrategy(lp, strategy.address).then(() => {
      controller.setStrategy(lp, strategy.address);
    })
  })
};
