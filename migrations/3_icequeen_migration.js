const IceQueen = artifacts.require("IceQueen");
const Snowball = artifacts.require("Snowball");

module.exports = async function (deployer) {
  let accounts = await web3.eth.getAccounts();
  const devfund = accounts[0];
  const treasury = accounts[0];

  let startblock = (await web3.eth.getBlockNumber()) + 600; // 10 minutes 600
  let endblock = (await web3.eth.getBlockNumber()) + 5000600; // to be changed to 5m past launch
  const snowballperblock = "1000000000000000000"; // 1x in wei

  let snowball = await Snowball.deployed();

  await deployer.deploy(IceQueen, snowball.address, devfund, treasury, snowballperblock, startblock, endblock);
}