const {expect} = require("chai");
const hre = require("hardhat");
const {ethers, upgrades} = require("hardhat");
const {advanceSevenDays} = require("./testHelper");

const governanceAddr = "0x9d074E37d408542FD38be78848e8814AFB38db17";
const masterChefAddr = "0xbD17B1ce622d73bD438b9E658acA5996dc394b0d";
const userAddr = "0xaCfE4511CE883C14c4eA40563F176C3C09b4c47C";
const pickleLP = "0xdc98556Ce24f007A5eF6dC1CE96322d65832A819";
const pickleAddr = "0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5";
const pyveCRVETH = "0x5eff6d166d66bacbc1bf52e2c54dd391ae6b1f48";
const dillHolder1Addr = "0x9d074e37d408542fd38be78848e8814afb38db17";
const dillHolder2Addr = "0x696A27eA67Cec7D3DA9D3559Cb086db0e814FeD3";
const dillHolder3Addr = "0x5c4D8CEE7dE74E31cE69E76276d862180545c307";

let GaugeProxyV2, userSigner, populatedTx, masterChef, pickle;

describe("vote & distribute", () => {
  before("setting up gaugeProxyV2", async () => {
    /**
     *  sending gas cost to gov
     * */
    const signer = ethers.provider.getSigner();

    console.log((await signer.getBalance()).toString());

    console.log("-- Sending gas cost to governance addr --");
    await signer.sendTransaction({
      to: governanceAddr,
      value: ethers.BigNumber.from("10000000000000000000"),
      data: undefined,
    });

    await signer.sendTransaction({
      to: dillHolder1Addr,
      value: ethers.BigNumber.from("1000000000000000000"),
      data: undefined,
    });
    await signer.sendTransaction({
      to: dillHolder2Addr,
      value: ethers.BigNumber.from("1000000000000000000"),
      data: undefined,
    });
    await signer.sendTransaction({
      to: dillHolder3Addr,
      value: ethers.BigNumber.from("1000000000000000000"),
      data: undefined,
    });
    /** unlock governance account */
    await hre.network.provider.request({
      method: "evm_unlockUnknownAccount",
      params: [governanceAddr],
    });

    /** unlock dill holders accounts */
    await hre.network.provider.request({
      method: "evm_unlockUnknownAccount",
      params: [userAddr],
    });

    await hre.network.provider.request({
      method: "evm_unlockUnknownAccount",
      params: [dillHolder1Addr],
    });

    await hre.network.provider.request({
      method: "evm_unlockUnknownAccount",
      params: [dillHolder2Addr],
    });

    await hre.network.provider.request({
      method: "evm_unlockUnknownAccount",
      params: [dillHolder3Addr],
    });

    const governanceSigner = ethers.provider.getSigner(governanceAddr);
    userSigner = ethers.provider.getSigner(userAddr);
    masterChef = await ethers.getContractAt(
      "src/yield-farming/masterchef.sol:MasterChef",
      masterChefAddr,
      governanceSigner
    );
    masterChef.connect(governanceSigner);

    /** Deploy gaugeProxyV2 */
    console.log("-- Deploying GaugeProxy v2 contract --");
    const gaugeProxyV2 = await ethers.getContractFactory("/src/dill/gauge-proxy-v2.sol:GaugeProxyV2", governanceSigner);
    console.log("Deploying GaugeProxyV2...");
    // getting timestamp
    const blockNumBefore = await ethers.provider.getBlockNumber();
    const blockBefore = await ethers.provider.getBlock(blockNumBefore);
    const timestampBefore = blockBefore.timestamp;

    GaugeProxyV2 = await upgrades.deployProxy(gaugeProxyV2, [timestampBefore], {
      initializer: "initialize",
    });
    await GaugeProxyV2.deployed();
    console.log("GaugeProxyV2 deployed to:", GaugeProxyV2.address);

    /** Add mDILL to MasterChef */
    const mDILLAddr = await GaugeProxyV2.TOKEN();
    console.log("-- Adding mDILL to MasterChef --");
    let populatedTx;
    populatedTx = await masterChef.populateTransaction.add(
      5000000,
      mDILLAddr,
      false
      // { gasLimit: 9000000 }
    );
    await governanceSigner.sendTransaction(populatedTx);

    /** Deploy gaugeMiddleware */
    console.log("-- Deploying GaugeMiddleware contract --");
    const gaugeMiddleware = await ethers.getContractFactory(
      "/src/dill/gauge-middleware.sol:GaugeMiddleware",
      governanceSigner
    );

    const GaugeMiddleware = await upgrades.deployProxy(gaugeMiddleware, [GaugeProxyV2.address, governanceAddr], {
      initializer: "initialize",
    });
    await GaugeMiddleware.deployed();
    console.log("gaugeMiddleware deployed at", GaugeMiddleware.address);

    /** add gaugeMiddleware*/
    await GaugeProxyV2.addGaugeMiddleware(GaugeMiddleware.address);

    /** add gauge*/
    console.log("-- Adding PICKLE LP Gauge --");
    await GaugeProxyV2.addGauge(pickleLP);

    console.log("-- Adding pyveCRVETH Gauge --");
    await GaugeProxyV2.addGauge(pyveCRVETH);

    const pidDill = (await masterChef.poolLength()) - 1;
    await GaugeProxyV2.setPID(pidDill);
    await GaugeProxyV2.deposit();

    pickle = await ethers.getContractAt("src/yield-farming/pickle-token.sol:PickleToken", pickleAddr);
    // dill = await ethers.getContractAt("src/DillABI:dillAbi", dillAddr);
    // console.log(await dill.totalSupply());
  });

  it("should vote successfully with -ve votes(first voting)", async () => {
    console.log("-- Voting on LP Gauge with negative weight --");
    const gaugeProxyFromUser = GaugeProxyV2.connect(userAddr);
    populatedTx = await gaugeProxyFromUser.populateTransaction.vote([pickleLP, pyveCRVETH], [-4000000, 6000000], {
      gasLimit: 9000000,
    });
    await userSigner.sendTransaction(populatedTx);
    await hre.network.provider.request({
      method: "evm_mine",
    });
  });

  it("successfully Distribute(initial) PICKLE to gauges advancing 7 days", async () => {
    await advanceSevenDays();
    console.log("currentId", (await GaugeProxyV2.getCurrentPeriodId()).toString());
    console.log("distributionId", (await GaugeProxyV2.distributionId()).toString());

    await GaugeProxyV2.distribute(0, 2);

    const pickleGaugeAddr = await GaugeProxyV2.getGauge(pickleLP);
    const yvecrvGaugeAddr = await GaugeProxyV2.getGauge(pyveCRVETH);

    const pickleRewards = await pickle.balanceOf(pickleGaugeAddr);
    console.log("rewards to Pickle gauge", pickleRewards.toString());

    const yvecrvRewards = await pickle.balanceOf(yvecrvGaugeAddr);
    console.log("rewards to pyveCRV gauge", yvecrvRewards.toString());
  });

  it("Should test total aggregate voting successfully", async () => {
    const dillHolder1 = ethers.provider.getSigner(dillHolder1Addr);
    const dillHolder2 = ethers.provider.getSigner(dillHolder2Addr);
    const dillHolder3 = ethers.provider.getSigner(dillHolder3Addr);
    // GaugeProxyV2 by user
    const GaugeV2By1 = GaugeProxyV2.connect(dillHolder1);
    const GaugeV2By2 = GaugeProxyV2.connect(dillHolder2);
    const GaugeV2By3 = GaugeProxyV2.connect(dillHolder3);

    // vote by Luffy
    console.log("-- Voting on LP Gauge with by Luffy --");
    populatedTx = await GaugeV2By1.populateTransaction.vote([pickleLP, pyveCRVETH], [4000000, -1000000], {
      gasLimit: 9000000,
    });
    await dillHolder1.sendTransaction(populatedTx);

    // vote by Zoro
    console.log("-- Voting on LP Gauge with by Zoro --");
    populatedTx = await GaugeV2By2.populateTransaction.vote([pickleLP, pyveCRVETH], [4000000, -4000000], {
      gasLimit: 9000000,
    });
    await dillHolder2.sendTransaction(populatedTx);

    //1 vote by Sanji
    console.log("-- Voting on LP Gauge with by Sanji --");
    populatedTx = await GaugeV2By3.populateTransaction.vote([pickleLP, pyveCRVETH], [4000000, -1000000], {
      gasLimit: 9000000,
    });
    await dillHolder3.sendTransaction(populatedTx);

    await advanceSevenDays();
    //2
    console.log("-- Voting on LP Gauge with by Sanji --");
    populatedTx = await GaugeV2By3.populateTransaction.vote([pickleLP, pyveCRVETH], [4000000, -1000000], {
      gasLimit: 9000000,
    });
    await dillHolder3.sendTransaction(populatedTx);

    await advanceSevenDays();
    //3
    console.log("-- Voting on LP Gauge with negative weight by Sanji --");
    populatedTx = await GaugeV2By3.populateTransaction.vote([pickleLP, pyveCRVETH], [4000000, -1000000], {
      gasLimit: 9000000,
    });
    await dillHolder3.sendTransaction(populatedTx);

    await advanceSevenDays();
    //4
    console.log("-- Voting on LP Gauge with negative weight by Sanji --");
    populatedTx = await GaugeV2By3.populateTransaction.vote([pickleLP, pyveCRVETH], [4000000, -1000000], {
      gasLimit: 9000000,
    });
    await dillHolder3.sendTransaction(populatedTx);

    await advanceSevenDays();
    //5
    console.log("-- Voting on LP Gauge with negative weight by Sanji --");
    populatedTx = await GaugeV2By3.populateTransaction.vote([pickleLP, pyveCRVETH], [4000000, -1000000], {
      gasLimit: 9000000,
    });
    await dillHolder3.sendTransaction(populatedTx);

    await hre.network.provider.request({
      method: "evm_mine",
    });

    // console.log("Total weight =>",Number(await GaugeProxyV2.totalWeight(1)));
    // rewards to Pickle gauge 79936051158800000
    // rewards to pyveCRV gauge 119904076738200000
    // rewards to pyveCRV gauge 177537555187922547
    // distribute

    await advanceSevenDays();
    console.log("currentId", (await GaugeProxyV2.getCurrentPeriodId()).toString());
    console.log("distributionId", (await GaugeProxyV2.distributionId()).toString());

    const pickleGaugeAddr = await GaugeProxyV2.getGauge(pickleLP);
    const yvecrvGaugeAddr = await GaugeProxyV2.getGauge(pyveCRVETH);

    const pickleRewards = await pickle.balanceOf(pickleGaugeAddr);
    console.log("rewards to Pickle gauge", pickleRewards.toString());

    const yvecrvRewards = await pickle.balanceOf(yvecrvGaugeAddr);
    console.log("rewards to pyveCRV gauge", yvecrvRewards.toString());
  });
  it("Should successfully test delist gauge", async () => {
    const dillHolder3 = ethers.provider.getSigner(dillHolder3Addr);
    await expect(GaugeProxyV2.delistGauge(masterChefAddr)).to.be.revertedWith("!exists");
    await expect(GaugeProxyV2.connect(dillHolder3).delistGauge(pyveCRVETH)).to.be.revertedWith("!gov");
    await expect(GaugeProxyV2.delistGauge(pyveCRVETH)).to.be.revertedWith("! all distributions completed");

    console.log("currentId", (await GaugeProxyV2.getCurrentPeriodId()).toString());
    console.log("distributionId", (await GaugeProxyV2.distributionId()).toString());
    console.log("-- Distributing 5 times -- ");
    await GaugeProxyV2.distribute(0, 2);
    await GaugeProxyV2.distribute(0, 2);
    await GaugeProxyV2.distribute(0, 2);
    await GaugeProxyV2.distribute(0, 2);
    await GaugeProxyV2.distribute(0, 2);

    await expect(GaugeProxyV2.delistGauge(pickleLP)).to.be.revertedWith("censors < 5");
    console.log("currentId", (await GaugeProxyV2.getCurrentPeriodId()).toString());
    console.log("distributionId", (await GaugeProxyV2.distributionId()).toString());

    const pickleGaugeAddr = await GaugeProxyV2.getGauge(pickleLP);
    const yvecrvGaugeAddr = await GaugeProxyV2.getGauge(pyveCRVETH);

    const pickleRewards = await pickle.balanceOf(pickleGaugeAddr);
    console.log("rewards to Pickle gauge", pickleRewards.toString());

    const yvecrvRewards = await pickle.balanceOf(yvecrvGaugeAddr);
    console.log("rewards to pyveCRV gauge", yvecrvRewards.toString());

    console.log(
      "-- pickleLP gauge with -ve weight ",
      Number(await GaugeProxyV2.gaugeWithNegativeWeight(pickleGaugeAddr))
    );
    console.log(
      "-- pyveCRVETH gauge with -ve weight ",
      Number(await GaugeProxyV2.gaugeWithNegativeWeight(yvecrvGaugeAddr))
    );

    console.log("-- Removing gauge with -ve aggregate voting > 5 --");
    await GaugeProxyV2.delistGauge(pyveCRVETH);
  });
});
