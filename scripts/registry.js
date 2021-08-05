async function main() {
  // We get the contract to deploy
  const PickleRegistry = await ethers.getContractFactory("PickleRegistry");
  const registry = await PickleRegistry.deploy();

  console.log("Registry deployed to:", registry.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });