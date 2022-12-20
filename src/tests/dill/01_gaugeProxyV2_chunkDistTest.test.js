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
const zeroAddr = "0x0000000000000000000000000000000000000000";
let GaugeProxyV2, userSigner, populatedTx, masterChef, GaugeMiddleware;

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

    /** unlock user's account */
    await hre.network.provider.request({
      method: "evm_unlockUnknownAccount",
      params: [userAddr],
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

    // getting block timestamp
    const blockNumBefore = await ethers.provider.getBlockNumber();
    const blockBefore = await ethers.provider.getBlock(blockNumBefore);
    const timestampBefore = blockBefore.timestamp;
    console.log(timestampBefore);

    GaugeProxyV2 = await upgrades.deployProxy(gaugeProxyV2, [timestampBefore + 86400 * 7], {
      initializer: "initialize",
    });
    await GaugeProxyV2.deployed();
    console.log("GaugeProxyV2 deployed to:", GaugeProxyV2.address);

    const mDILLAddr = await GaugeProxyV2.TOKEN();
    console.log("-- Adding mDILL to MasterChef --");

    populatedTx = await masterChef.populateTransaction.add(5000000, mDILLAddr, false);
    await governanceSigner.sendTransaction(populatedTx);

    console.log("-- Deploying GaugeMiddleware contract --");
    const gaugeMiddleware = await ethers.getContractFactory(
      "/src/dill/gauge-middleware.sol:GaugeMiddleware",
      governanceSigner
    );

    /** Deploy gaugeMiddleware should fail */
    await expect(
      upgrades.deployProxy(gaugeMiddleware, [governanceAddr, governanceAddr], {
        initializer: "initialize",
      })
    ).to.be.revertedWith("_governance address and _gaugeProxy cannot be same");

    /** Deploy gaugeMiddleware should fail */
    await expect(
      upgrades.deployProxy(gaugeMiddleware, [zeroAddr, governanceAddr], {
        initializer: "initialize",
      })
    ).to.be.revertedWith("_gaugeProxy address cannot be set to zero");

    /** Deploy gaugeMiddleware successfully */
    GaugeMiddleware = await upgrades.deployProxy(gaugeMiddleware, [masterChefAddr, governanceAddr], {
      initializer: "initialize",
    });
    await GaugeMiddleware.deployed();
    console.log("gaugeMiddleware deployed at", GaugeMiddleware.address);
  });

  beforeEach(async () => {
    console.log("Current Id => ", Number(await GaugeProxyV2.getCurrentPeriodId()));
    console.log("Distribution Id => ", Number(await GaugeProxyV2.distributionId()));
  });
  it("change gauge gaugeProxy in middleware and add gauges successfully", async () => {
    const governanceSigner = ethers.provider.getSigner(governanceAddr);
    await expect(GaugeMiddleware.connect(userSigner).changeGaugeProxy(GaugeProxyV2.address)).to.be.revertedWith(
      "can only be called by governance"
    );

    await GaugeMiddleware.connect(governanceSigner).changeGaugeProxy(GaugeProxyV2.address);

    /** add gaugeMiddleware*/
    console.log("-- Adding Gauge middleWare --");

    await expect(GaugeProxyV2.addGaugeMiddleware(zeroAddr)).to.be.revertedWith("gaugeMiddleware cannot set to zero");
    await GaugeProxyV2.connect(governanceSigner).addGaugeMiddleware(GaugeMiddleware.address);
    await expect(GaugeProxyV2.addGaugeMiddleware(GaugeMiddleware.address)).to.be.revertedWith(
      "current and new gaugeMiddleware are same"
    );

    await expect(GaugeProxyV2.addGauge(zeroAddr)).to.be.revertedWith("address of token cannot be zero");

    await expect(GaugeMiddleware.addGauge(zeroAddr, governanceAddr, ["PICKLE"], [pickleAddr])).to.be.revertedWith(
      "can only be called by gaugeProxy"
    );
    console.log("-- Adding PICKLE LP Gauge --");
    await GaugeProxyV2.addGauge(pickleLP);

    console.log("-- Adding pyveCRVETH Gauge --");
    await GaugeProxyV2.addGauge(pyveCRVETH);

    console.log("tokens length", Number(await GaugeProxyV2.length()));
  });
  it("Should successfully test first voting", async () => {
    const gaugeProxyFromUser = GaugeProxyV2.connect(userSigner);
    console.log("-- Voting on LP Gauge with 100% weight --");

    await expect(
      gaugeProxyFromUser.vote([pickleLP, pyveCRVETH], [6000000, 4000000], {
        gasLimit: 9000000,
      })
    ).to.be.revertedWith("Voting not started yet");

    await expect(gaugeProxyFromUser.reset()).to.be.revertedWith("Voting not started");

    advanceSevenDays();
    console.log("Current Id => ", Number(await GaugeProxyV2.getCurrentPeriodId()));
    console.log("Distribution Id => ", Number(await GaugeProxyV2.distributionId()));

    populatedTx = await gaugeProxyFromUser.populateTransaction.vote([pickleLP, pyveCRVETH], [6000000, 4000000], {
      gasLimit: 9000000,
    });
    await userSigner.sendTransaction(populatedTx);

    const pidDill = (await masterChef.poolLength()) - 1;
    await GaugeProxyV2.setPID(pidDill);
    await GaugeProxyV2.deposit();

    // Adjusts _owner's votes according to latest _owner's DILL balance
    await GaugeProxyV2.poke(userAddr);
    const tokensAry = await GaugeProxyV2.tokens();

    console.log("users pickleLP votes =>", await GaugeProxyV2.votes(userAddr, tokensAry[0]));
    console.log("users pyveCRVETH votes =>", await GaugeProxyV2.votes(userAddr, tokensAry[1]));

    //reset users vote
    await gaugeProxyFromUser.reset();
    let pickleLPVotes = await GaugeProxyV2.votes(userAddr, tokensAry[0]);
    let pyveCRVETHVotes = await GaugeProxyV2.votes(userAddr, tokensAry[1]);
    expect(pickleLPVotes).to.equal(0);
    expect(pyveCRVETHVotes).to.equal(0);

    // vote again
    await gaugeProxyFromUser.vote([pickleLP, pyveCRVETH], [6000000, 4000000], {
      gasLimit: 9000000,
    });
    pickleLPVotes = await GaugeProxyV2.votes(userAddr, pickleLP);
    pyveCRVETHVotes = await GaugeProxyV2.votes(userAddr, pyveCRVETH);
    expect(Number(pickleLPVotes)).to.greaterThan(0);
    expect(Number(pyveCRVETHVotes)).to.greaterThan(0);
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
    await GaugeProxyV2.distribute(0, 1, {
      gasLimit: 900000,
    });

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
    await GaugeProxyV2.distribute(0, 1, {
      gasLimit: 900000,
    });

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
    await GaugeProxyV2.distribute(1, 2, {
      gasLimit: 900000,
    });
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
