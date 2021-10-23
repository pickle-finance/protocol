const { expect } = require("chai");
const hre = require("hardhat");
const {ZERO_ADDRESS} = require("../utils/constants");
const {increaseBlock} = require("../utils/testHelper");

const governanceAddr = "0x9d074E37d408542FD38be78848e8814AFB38db17";
const masterChefAddr = "0xbD17B1ce622d73bD438b9E658acA5996dc394b0d";
const userAddr = "0x9bd920252E388579770B2CcA855f81ABAbD22A84";

const pickleLP = "0xdc98556Ce24f007A5eF6dC1CE96322d65832A819";
const pickleAddr = "0x429881672B9AE42b8EbA0E26cD9C73711b891Ca5";
const pyveCRVETH = "0x5eff6d166d66bacbc1bf52e2c54dd391ae6b1f48";

describe('GaugeProxy', () => {
  const ethers = hre.ethers;

  let factory;
  let registry;
  let governance;
  let other;
  let addresses;

  beforeEach(async () => {
    factory = await ethers.getContractFactory("GaugeProxy");
    await network.provider.send("hardhat_setBalance", [
        governanceAddr,
        "0x56BC75E2D60000000", //100 Ether
     ]);

    await hre.network.provider.request({
       method: "hardhat_impersonateAccount",
       params: [governanceAddr],
     });
     const governanceSigner = ethers.provider.getSigner(governanceAddr);
     const userSigner = ethers.provider.getSigner(userAddr);

     const masterChef = await ethers.getContractAt(
       "src/yield-farming/masterchef.sol:MasterChef",
       masterChefAddr,
       governanceSigner
     );
     masterChef.connect(governanceSigner);
     gaugeproxy = await factory.deploy();

  });

  describe('Test Basic Gauge', () => {
    it('addGauge', async () => {
      expect(await gaugeproxy.tokens()).to.eql([]);
      await gaugeproxy.addGauge(pickleLP);
      let actual = await gaugeproxy.tokens();
      expect(actual[0]).to.equal(pickleLP);
    });
    it('removeGauge', async() => {
      expect(await gaugeproxy.tokens()).to.eql([]);
      await expect(gaugeproxy.removeGauge(pickleLP)).to.be.revertedWith('!exists');
    });
    it('Add then Remove Gauge', async () => {
      await gaugeproxy.addGauge(pickleLP);
      expect(await gaugeproxy.tokens()).to.eql([pickleLP]);
      await gaugeproxy.removeGauge(pickleLP);
      expect(await gaugeproxy.tokens()).to.eql([ZERO_ADDRESS]);
      await gaugeproxy.addGauge(pickleLP);
      expect(await gaugeproxy.tokens()).to.eql([ZERO_ADDRESS,pickleLP]);
    });
  });
  describe('Test Distribution', () => {
    it('generic distribution', async() =>{

      const mDILLAddr = await gaugeproxy.TOKEN();
      const governanceSigner = ethers.provider.getSigner(governanceAddr);
      const userSigner = ethers.provider.getSigner(userAddr);
      const masterChef = await ethers.getContractAt(
        "src/yield-farming/masterchef.sol:MasterChef",
        masterChefAddr,
        governanceSigner
      );
      masterChef.connect(governanceSigner);

      let populatedTx;
      populatedTx = await masterChef.populateTransaction.add(
        10,
        mDILLAddr,
        false,
        { gasLimit: 9000000 }
      );
      await governanceSigner.sendTransaction(populatedTx);

      await gaugeproxy.addGauge(pickleLP);
      await gaugeproxy.addGauge(pyveCRVETH);

      await hre.network.provider.request({
        method: "hardhat_impersonateAccount",
        params: [userAddr],
      });

      const gaugeProxyFromUser = gaugeproxy.connect(userAddr);
      populatedTx = await gaugeProxyFromUser.populateTransaction.vote(
        [pickleLP, pyveCRVETH],
        [6000000, 4000000],
        {
          gasLimit: 9000000,
        }
      );
      await userSigner.sendTransaction(populatedTx);
      const pidDill = (await masterChef.poolLength()) - 1;
      await gaugeproxy.setPID(pidDill);
      await gaugeproxy.deposit();


      expect(await gaugeproxy.deadWeight()).to.equal(0);


      increaseBlock(10);

      const pickleGaugeAddr = await gaugeproxy.getGauge(pickleLP);
      const yvecrvGaugeAddr = await gaugeproxy.getGauge(pyveCRVETH);
      const pickle = await ethers.getContractAt("src/yield-farming/pickle-token.sol:PickleToken", pickleAddr);

      const pre_pickleRewards = await pickle.balanceOf(pickleGaugeAddr);
      const pre_yvecrvRewards = await pickle.balanceOf(yvecrvGaugeAddr);

      console.log("Pre-Rewards to Pickle gauge", pre_pickleRewards);
      await gaugeproxy.distribute();

      const pickleRewards = await pickle.balanceOf(pickleGaugeAddr);
      const yvecrvRewards = await pickle.balanceOf(yvecrvGaugeAddr);
      console.log("Rewards to Pickle gauge", pre_pickleRewards);
      expect(pickleRewards).to.be.gt(pre_pickleRewards);
      expect(yvecrvRewards).to.be.gt(pre_yvecrvRewards);

      await gaugeproxy.removeGauge(pyveCRVETH);

      increaseBlock(10);
      await gaugeproxy.distribute();

      const post_pickleRewards = await pickle.balanceOf(pickleGaugeAddr);
      const post_yvecrvRewards = await pickle.balanceOf(yvecrvGaugeAddr);
      console.log("Post-Rewards to Pickle gauge", pre_pickleRewards);
      expect(post_pickleRewards).to.be.gt(pickleRewards);
      expect(post_yvecrvRewards).to.equal(yvecrvRewards);
      expect(await gaugeproxy.deadWeight()).to.be.gt(0);

    })
  })
});
