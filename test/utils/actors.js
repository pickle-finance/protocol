const hre = require("hardhat");
const { ethers, network } = require("hardhat");

const setupSigners = async () => {
  const controllerAddr = "0xf7B8D9f8a82a7a6dd448398aFC5c77744Bd6cb85";
  const timelockAddr = "0xdbc195a0ed72c0b059f8906e97a90636d2b6409f";
  const governanceAddr = "0x294aB3200ef36200db84C4128b7f1b4eec71E38a";
  const strategistAddr = "0xc9a51fb9057380494262fd291aed74317332c0a2";

  await network.provider.send('hardhat_impersonateAccount', [timelockAddr]);
  await network.provider.send('hardhat_impersonateAccount', [strategistAddr]);
  await network.provider.send('hardhat_impersonateAccount', [controllerAddr]);
  await network.provider.send('hardhat_impersonateAccount', [governanceAddr]);

  let timelockSigner = ethers.provider.getSigner(timelockAddr);
  let strategistSigner = ethers.provider.getSigner(strategistAddr);
  let controllerSigner = ethers.provider.getSigner(controllerAddr);
  let governanceSigner = ethers.provider.getSigner(governanceAddr);

  return [timelockSigner,strategistSigner,controllerSigner,governanceSigner]
}


module.exports = {
  setupSigners
}