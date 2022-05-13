const {advanceSevenDays} = require("./testHelper");
const hre = require("hardhat");
const {ethers, upgrades} = require("hardhat");
const {expect} = require("chai");

const governanceAddr = "0x9d074E37d408542FD38be78848e8814AFB38db17";
const masterChefAddr = "0xbD17B1ce622d73bD438b9E658acA5996dc394b0d";
const userAddr = "0xaCfE4511CE883C14c4eA40563F176C3C09b4c47C";
const pickleLP = "0xdc98556Ce24f007A5eF6dC1CE96322d65832A819";
const pickleAddr = "0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5";
const pyveCRVETH = "0x5eff6d166d66bacbc1bf52e2c54dd391ae6b1f48";
let GaugeProxyV2, userSigner, populatedTx, masterChef;

describe("Vote & Distribute : chunk and onlyGov distribution", () => {
  before("Setting up gaugeProxyV2", async () => {
    /**
     *  sending gas cost to gov
     * */
    const signer = ethers.provider.getSigner();
    console.log("-- Sending gas cost to governance addr --");
    await signer.sendTransaction({
      to: governanceAddr,
      value: ethers.BigNumber.from("10000000000000000000"), // 1000 ETH
      data: undefined,
    });

    /** unlock governance account */
    await hre.network.provider.request({
      method: "evm_unlockUnknownAccount",
      params: [governanceAddr],
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
    GaugeProxyV2 = await upgrades.deployProxy(gaugeProxyV2, [Math.round(new Date().getTime() / 1000)], {
      initializer: "initialize",
    });
    await GaugeProxyV2.deployed();
    console.log("GaugeProxyV2 deployed to:", GaugeProxyV2.address);

    const mDILLAddr = await GaugeProxyV2.TOKEN();
    console.log("-- Adding mDILL to MasterChef --");

    populatedTx = await masterChef.populateTransaction.add(
      5000000,
      mDILLAddr,
      false
    );
    await governanceSigner.sendTransaction(populatedTx);

    console.log("-- Adding PICKLE LP Gauge --");
    await GaugeProxyV2.addGauge(pickleLP);

    console.log("-- Adding pyveCRVETH Gauge --");
    await GaugeProxyV2.addGauge(pyveCRVETH);

    await hre.network.provider.request({
      method: "evm_unlockUnknownAccount",
      params: [userAddr],
    });
  });

  beforeEach(async () => {
    console.log("Current Id => ", Number(await GaugeProxyV2.getCurrentPeriodId()));
    console.log("Distribution Id => ", Number(await GaugeProxyV2.distributionId()));
  });

  it("Should vote successfully (first voting)", async () => {
    console.log("-- Voting on LP Gauge with 100% weight --");
    const gaugeProxyFromUser = GaugeProxyV2.connect(userAddr);
    populatedTx = await gaugeProxyFromUser.populateTransaction.vote([pickleLP, pyveCRVETH], [6000000, 4000000], {
      gasLimit: 9000000,
    });
    await userSigner.sendTransaction(populatedTx);

    const pidDill = (await masterChef.poolLength()) - 1;
    await GaugeProxyV2.setPID(pidDill);
    await GaugeProxyV2.deposit();

    await hre.network.provider.request({
      method: "evm_mine",
    });
  });

  it("OnlyGov : distribution by non-gov address Should fail", async () => {
    const gaugeProxyFromUser = GaugeProxyV2.connect(userAddr);
    populatedTx = await gaugeProxyFromUser.populateTransaction.distribute(0, 2);
    await expect(userSigner.sendTransaction(populatedTx)).to.be.revertedWith(
      "GaugeProxyV2: only governance can distribute"
    );
  });

  it("Distribute(onlyGov) PICKLE to gauges Should fail as voting still in progress", async () => {
    await expect(GaugeProxyV2.distribute(0, 2)).to.be.revertedWith("GaugeProxyV2: all period distributions complete");
  });

  it("Distribution Should fail when end greater than token[] length is passed ", async () => {
    await advanceSevenDays();
    await expect(GaugeProxyV2.distribute(0, 3)).to.be.revertedWith("GaugeProxyV2: bad _end");
  });

  it("Successfully Distribute PICKLE(in chunks) to gauges in chunks after advancing 7 days", async () => {
    /**
     * FIRST CHUNK DISTRIBUTION (successful)
     */
    console.log("-- Distributing first chunk (0,1) --");
    await GaugeProxyV2.distribute(0, 1);
    let pickleGaugeAddr = await GaugeProxyV2.getGauge(pickleLP);
    let yvecrvGaugeAddr = await GaugeProxyV2.getGauge(pyveCRVETH);

    const pickle = await ethers.getContractAt("src/yield-farming/pickle-token.sol:PickleToken", pickleAddr);

    let pickleRewards = Number(await pickle.balanceOf(pickleGaugeAddr));
    console.log("Rewards to Pickle gauge => ", pickleRewards.toString());

    let yvecrvRewards = Number(await pickle.balanceOf(yvecrvGaugeAddr));
    console.log("Rewards to pyveCRV gauge => ", yvecrvRewards.toString());
    expect(pickleRewards).to.greaterThan(0);
    expect(yvecrvRewards).to.equal(0);
  });

  it("Should not distribute rewards to gauges when tried to distribute same chunk again", async () => {
    /**
     * FIRST CHUNK DISTRIBUTION (fail)
     */
    console.log("Distributing first chunk(0, 1) again");
    await GaugeProxyV2.distribute(0, 1);
   
    let pickleGaugeAddr = await GaugeProxyV2.getGauge(pickleLP);
    let yvecrvGaugeAddr = await GaugeProxyV2.getGauge(pyveCRVETH);

    const pickle = await ethers.getContractAt("src/yield-farming/pickle-token.sol:PickleToken", pickleAddr);

    let pickleRewards = await pickle.balanceOf(pickleGaugeAddr);
    console.log("Rewards to Pickle gauge => ", pickleRewards.toString());

    let yvecrvRewards = await pickle.balanceOf(yvecrvGaugeAddr);
    console.log("Rewards to pyveCRV gauge => ", yvecrvRewards.toString());
  });

  it("Should fail when tried to pass wrong start", async () => {
    /**
     * SECOND CHUNK DISTRIBUTION (fail)
     */
    console.log("--Distributing chunk with wrong start--");
    await expect(GaugeProxyV2.distribute(2, 2)).to.be.revertedWith("GaugeProxyV2: bad _start");
  });

  it("Successfully Distribute PICKLE to gauges in chunks after advancing 7 days", async () => {
    /**
     * SECOND CHUNK DISTRIBUTION (successful)
     */
    console.log("--Distributing second chunk(0,2)--");
    await GaugeProxyV2.distribute(1, 2);
    let pickleGaugeAddr = await GaugeProxyV2.getGauge(pickleLP);
    let yvecrvGaugeAddr = await GaugeProxyV2.getGauge(pyveCRVETH);

    const pickle = await ethers.getContractAt("src/yield-farming/pickle-token.sol:PickleToken", pickleAddr);

    let pickleRewards = Number(await pickle.balanceOf(pickleGaugeAddr));
    console.log("Rewards to Pickle gauge => ", pickleRewards.toString());

    let yvecrvRewards = Number(await pickle.balanceOf(yvecrvGaugeAddr));
    console.log("Rewards to pyveCRV gauge => ", yvecrvRewards.toString());
    expect(yvecrvRewards).to.greaterThan(0);
  });
});
