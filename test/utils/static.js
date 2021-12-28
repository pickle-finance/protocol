const hre = require("hardhat");
const { ethers, network } = require("hardhat");

const setupSigners = async () => {
  const timelock_addr = "0xc9a51fb9057380494262fd291aed74317332c0a2";
  const governance_addr = "0x294aB3200ef36200db84C4128b7f1b4eec71E38a";
  const strategist_addr = "0xc9a51fb9057380494262fd291aed74317332c0a2";

  await network.provider.send('hardhat_impersonateAccount', [timelock_addr]);
  await network.provider.send('hardhat_impersonateAccount', [strategist_addr]);
  await network.provider.send('hardhat_impersonateAccount', [governance_addr]);

  let timelockSigner = ethers.provider.getSigner(timelock_addr);
  let strategistSigner = ethers.provider.getSigner(strategist_addr);
  let governanceSigner = ethers.provider.getSigner(governance_addr);

  await network.provider.send("hardhat_setBalance", [governanceSigner._address,"0x10000000000000000000000",]);
  await network.provider.send("hardhat_setBalance", [timelockSigner._address,"0x10000000000000000000000",]);
  await network.provider.send("hardhat_setBalance", [strategistSigner._address,"0x10000000000000000000000",]);

  return [timelockSigner,strategistSigner,governanceSigner];
};

const snowball_addr = "0xC38f41A296A4493Ff429F1238e030924A1542e50";
const treasury_addr="0x028933a66dd0ccc239a3d5c2243b2d96672f11f5";
const dev_addr= "0x0aa5cb6f365259524f7ece8e09cce9a7b394077a";
  
const MAX_UINT256= ethers.constants.MaxUint256;

module.exports = {
  setupSigners,
  snowball_addr,
  treasury_addr,
  dev_addr,
  MAX_UINT256
};