const SnowGlobe = artifacts.require("SnowGlobe");
const StrategyPngAvaxSushiLp = artifacts.require("StrategyPngAvaxSushiLp");

module.exports = async function (deployer) {
  const governance = 0x294aB3200ef36200db84C4128b7f1b4eec71E38a;
  const timelock = governance;

  const controller = 0xf7B8D9f8a82a7a6dd448398aFC5c77744Bd6cb85;

  let strategy = await StrategyPngAvaxSushiLp.deployed();
  let lp = await strategy.want();

  await deployer.deploy(SnowGlobe, lp, governance, timelock, controller);
};
