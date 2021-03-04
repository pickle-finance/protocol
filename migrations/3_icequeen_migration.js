const IceQueen = artifacts.require("IceQueen");
const Snowball = artifacts.require("Snowball");

module.exports = async function (deployer) {
  let accounts = await web3.eth.getAccounts();
  const devpool = accounts[0];

  let startblock = (await web3.eth.getBlockNumber())+600; // 10 minutes
  let endblock = (await web3.eth.getBlockNumber()) + 5000600; // to be changed to 5m past launch // hold on gimme a minute
  const snowballperblock = 1000000000000000000; // 1x in wei

  let snowball = await Snowball.deployed();

  await deployer.deploy(IceQueen, snowball.address, devpool, snowballperblock, startblock, endblock);
}