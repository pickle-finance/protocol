const SnowToken = artifacts.require("SnowToken");

module.exports = async function (deployer) {
  let accounts = await web3.eth.getAccounts();
  const governance = accounts[0];

  await deployer.deploy(SnowToken);

};
