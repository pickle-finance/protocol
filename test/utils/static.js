const hre = require("hardhat");
const { ethers, network } = require("hardhat");

const setupSigners = async () => {
  const timelockAddr = "0xc9a51fb9057380494262fd291aed74317332c0a2";
  const governanceAddr = "0x294aB3200ef36200db84C4128b7f1b4eec71E38a";
  const strategistAddr = "0xc9a51fb9057380494262fd291aed74317332c0a2";

  await network.provider.send('hardhat_impersonateAccount', [timelockAddr]);
  await network.provider.send('hardhat_impersonateAccount', [strategistAddr]);
  await network.provider.send('hardhat_impersonateAccount', [governanceAddr]);

  let timelockSigner = ethers.provider.getSigner(timelockAddr);
  let strategistSigner = ethers.provider.getSigner(strategistAddr);
  let governanceSigner = ethers.provider.getSigner(governanceAddr);

  await network.provider.send("hardhat_setBalance", [governanceSigner._address,"0x10000000000000000000000",]);
  await network.provider.send("hardhat_setBalance", [timelockSigner._address,"0x10000000000000000000000",]);
  await network.provider.send("hardhat_setBalance", [strategistSigner._address,"0x10000000000000000000000",]);

  return [timelockSigner,strategistSigner,governanceSigner];
};

const snowballAddr = "0xC38f41A296A4493Ff429F1238e030924A1542e50";
const treasuryAddr="0x028933a66dd0ccc239a3d5c2243b2d96672f11f5";
const devAddr= "0x0aa5cb6f365259524f7ece8e09cce9a7b394077a";
  

module.exports = {
  setupSigners,
  snowballAddr,
  treasuryAddr,
  devAddr,
};