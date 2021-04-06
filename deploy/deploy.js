module.exports = async ({ getNamedAccounts, deployments }) => {
  const { deploy } = deployments;
  const { deployer } = await getNamedAccounts();

  await deploy("fee-distributor", {
    from: deployer,
    args: [
      "0xbBCf169eE191A1Ba7371F30A1C344bFC498b29Cf",
      "1617235200",
      "0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5",
      "0x1CbF903De5D688eDa7D6D895ea2F0a8F2A521E99",
      "0x066419EaEf5DE53cc5da0d8702b990c5bc7D1AB3",
    ],
    log: true,
  });
};
