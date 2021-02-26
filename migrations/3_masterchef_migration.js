const MasterChef = artifacts.require("MasterChef");
const PickleToken = artifacts.require("PickleToken");

module.exports = async function (deployer) {
  let accounts = await web3.eth.getAccounts();
  const devpool = accounts[0];

  let startblock = await web3.eth.getBlockNumber();
  let endblock = 200000000;
  const pickleperblock = 1000;

  let pickle = await PickleToken.deployed();

  await deployer.deploy(MasterChef, pickle.address, devpool, pickleperblock, startblock, endblock);
}