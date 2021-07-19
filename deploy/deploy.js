const governance = "0x9d074E37d408542FD38be78848e8814AFB38db17";
const strategist = "0xaCfE4511CE883C14c4eA40563F176C3C09b4c47C";
const controller = "0x6847259b2B3A4c17e7c43C54409810aF48bA5210";
const timelock = "0xD92c7fAa0Ca0e6AE4918f3a83d9832d9CAEAA0d3";

const mainnetStrategyArgs = [governance, strategist, controller, timelock]

const governancePoly = "0xacfe4511ce883c14c4ea40563f176c3c09b4c47c";
const strategistPoly = "0xacfe4511ce883c14c4ea40563f176c3c09b4c47c";
const controllerPoly = "0x83074F0aB8EDD2c1508D3F657CeB5F27f6092d09";
const timelockPoly = "0xacfe4511ce883c14c4ea40563f176c3c09b4c47c";

const polygonStrategyArgs = [governancePoly, strategistPoly, controllerPoly, timelockPoly]

const harvesters = [
  "0x0f571D2625b503BB7C1d2b5655b483a2Fa696fEf",
  "0xaCfE4511CE883C14c4eA40563F176C3C09b4c47C",
  "0xb4522eB2cA49963De9c3dC69023cBe6D53489C98"
];

const want = "0x7AfcF11F3e2f01e71B7Cc6b8B5e707E42e6Ea397";

const mainnetJarArgs = [want, governance, timelock, controller];
const polygonJarArgs = [want, governancePoly, timelockPoly, controllerPoly];

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, execute } = deployments;
  const { deployer } = await getNamedAccounts();

  await deploy("StrategyMaiQiMiMaticLp", {
    from: deployer,
    args: polygonStrategyArgs,
    log: true
  });

  await deploy("PickleJarDepositFeeInitializable", {
    from: deployer,
    args: [...polygonJarArgs, 50],
    log: true
  });

  await execute(
    "StrategyMaiQiMiMaticLp",
    { from: deployer, log: true },
    "whitelistHarvesters",
    harvesters
  );
};
