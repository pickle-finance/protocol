const ControllerV4 = artifacts.require("ControllerV4");

module.exports = async function (deployer) {
  let accounts = await web3.eth.getAccounts();
  const governance = accounts[0];
  const strategist = accounts[0];
  const devpool = accounts[0];
  const treasury = accounts[0];
  const timelock = governance;
  
  await deployer.deploy(ControllerV4, governance, strategist, timelock, devpool, treasury);
};
