// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");
const { ethers } = require("hardhat");

async function main() {
  const governanceAddr = "0x9d074E37d408542FD38be78848e8814AFB38db17";
  const userAddr = "0x1CbF903De5D688eDa7D6D895ea2F0a8F2A521E99";

  const pickleAddr = "0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5";

  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [governanceAddr],
  });

  const governanceSigner = ethers.provider.getSigner(governanceAddr);

  console.log("-- Deploying FeeShare contract --");
  const FeeShare = await hre.ethers.getContractFactory("FeeShare");
  const feeShare = await FeeShare.deploy();
  await feeShare.deployed();
  await feeShare.setStartTime(Math.floor(new Date() / 1000));

  console.log(`FeeShare deployed at ${feeShare.address}`);

  console.log("-- Waited a week before distributing --");
  await hre.network.provider.request({
    method: "evm_increaseTime",
    params: [3600 * 24 * 7],
  });
  await hre.network.provider.request({
    method: "evm_mine",
  });

  console.log("-- Distribute PICKLEs to fee sharing contract --");

  const picklesBN = ethers.utils.parseUnits("16");
  console.log(picklesBN);

  const pickle = await ethers.getContractAt("PickleToken", pickleAddr);

  console.log((await pickle.balanceOf(governanceAddr)).toString());

  await pickle.connect(governanceSigner).approve(
    feeShare.address,
    picklesBN // 16 PICKLEs
  );

  console.log("-- PICKLE spending approved --");

  await feeShare.connect(governanceSigner).distribute(
    picklesBN // 16 PICKLEs
  );

  console.log("-- PICKLE distributed to fee sharing contract --");

  const claimable = await feeShare.getClaimable(userAddr);
  console.log("claimable:", claimable.toString());

  const claimTx = await feeShare.connect(governanceSigner).claim(userAddr);
  const receipt = await claimTx.wait();

  console.log(
    "PICKLE rewards claimed: ",
    receipt.events
      .filter((x) => {
        return x.event == "Claim";
      })[0]
      .args.amount.toString()
  );
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
