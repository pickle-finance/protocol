const IceQueen = artifacts.require("IceQueen");
const SnowToken = artifacts.require("SnowToken");

module.exports = async function (deployer) {
  let accounts = await web3.eth.getAccounts();
  const devpool = accounts[0];

  let startblock = await web3.eth.getBlockNumber();
  let endblock = 200000000;
  const snowperblock = 1000;

  let snow = await SnowToken.deployed();

  await deployer.deploy(IceQueen, snow.address, devpool, snowperblock, startblock, endblock);
}