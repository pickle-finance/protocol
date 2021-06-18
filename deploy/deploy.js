const governance = "0x9d074E37d408542FD38be78848e8814AFB38db17";
const strategist = "0xaCfE4511CE883C14c4eA40563F176C3C09b4c47C";
const controller = "0x6847259b2B3A4c17e7c43C54409810aF48bA5210";
const timelock = "0xD92c7fAa0Ca0e6AE4918f3a83d9832d9CAEAA0d3";

const harvesters = [
  "0x0f571D2625b503BB7C1d2b5655b483a2Fa696fEf",
  "0xaCfE4511CE883C14c4eA40563F176C3C09b4c47C",
  "0xb4522eB2cA49963De9c3dC69023cBe6D53489C98",
];
const wmatic = "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270";
const rewardPerSecond = 0;
const minichef = "0x20b2a3fc7b13ca0ccf7af81a68a14cb3116e8749"

const want = "0x05767d9EF41dC40689678fFca0608878fb3dE906";

module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy, execute } = deployments;
  const { deployer } = await getNamedAccounts();

  await deploy("PickleRewarder", {
    from: deployer,
    args: [wmatic, rewardPerSecond, minichef],
    log: true,
  });

};
