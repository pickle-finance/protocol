const PickleJar = artifacts.require("PickleJar");
const ControllerV4 = artifacts.require("ControllerV4");
const StrategySushiEthDaiLp = artifacts.require("StrategySushiEthDaiLp");

module.exports = async function (deployer) {
  let accounts = await web3.eth.getAccounts();
  const governance = accounts[0];
  const strategist = accounts[1];
  const devpool = accounts[3];
  const treasury = accounts[4];
  const timelock = governance;


  let controller = await ControllerV4.deployed();
  let strategy = await StrategySushiEthDaiLp.deployed();
  let jar = await PickleJar.deployed();
  let lp = await strategy.want();

  controller.setJar(lp, jar.address).then(() => {
    controller.approveStrategy(lp, strategy.address).then(() => {
      controller.setStrategy(lp, strategy.address);
    })
  })
};
