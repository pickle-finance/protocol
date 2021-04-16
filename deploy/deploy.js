const governance = "0x9d074E37d408542FD38be78848e8814AFB38db17";
const strategist = "0xaCfE4511CE883C14c4eA40563F176C3C09b4c47C";
const controller = "0x6847259b2B3A4c17e7c43C54409810aF48bA5210";
const timelock = "0xD92c7fAa0Ca0e6AE4918f3a83d9832d9CAEAA0d3";

const harvesters = [
  "0x0f571D2625b503BB7C1d2b5655b483a2Fa696fEf",
  "0xaCfE4511CE883C14c4eA40563F176C3C09b4c47C",
  "0xb4522eB2cA49963De9c3dC69023cBe6D53489C98",
];

const want = "0x3E78F2E7daDe07ea685F8612F00477FD97162F1e";

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, execute } = deployments;
  const { deployer } = await getNamedAccounts();

  await deploy("StrategyBasisBasDaiLpV3", {
    from: deployer,
    args: [governance, strategist, controller, timelock],
    log: true,
  });

  await deploy("PickleJar", {
    from: deployer,
    args: [want, governance, timelock, controller],
    log: true,
  });

  await execute(
    "StrategyBasisBasDaiLpV3",
    { from: deployer, log: true },
    "whitelistHarvesters",
    harvesters
  );
};
