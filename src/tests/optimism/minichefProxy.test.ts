import "@nomicfoundation/hardhat-toolbox";
import {ethers} from "hardhat";
import {loadFixture} from "@nomicfoundation/hardhat-network-helpers";
import {expect, deployContract, toWei} from "../utils/testHelper";
import {BigNumber} from "ethers";

describe("MiniChefController", () => {
  const setupFixture = async () => {
    const [alice, governance, strategist] = await ethers.getSigners();

    const pickle = await deployContract("src/yield-farming/pickle-token.sol:PickleToken");
    const reward = await deployContract("src/yield-farming/pickle-token.sol:PickleToken");
    await pickle.mint(governance.address, toWei(10_000));
    await reward.mint(governance.address, toWei(10_000));

    const minichef = await deployContract("src/optimism/minichefv2.sol:MiniChefV2", pickle.address);
    const rewarder = await deployContract(
      "src/optimism/PickleRewarder.sol:PickleRewarder",
      reward.address,
      0,
      minichef.address
    );

    const jar1 = await deployContract("src/yield-farming/pickle-token.sol:PickleToken");
    const jar2 = await deployContract("src/yield-farming/pickle-token.sol:PickleToken");
    await jar1.mint(alice.address, toWei(10_000));
    await jar2.mint(alice.address, toWei(10_000));

    // Deploy the controller and transfer governance
    const miniChefController = await deployContract(
      "src/optimism/minichefProxy.sol:ChefProxy",
      minichef.address,
      rewarder.address
    );
    await miniChefController.setPendingGovernance(governance.address);
    await miniChefController.connect(governance).claimGovernance();

    // Transfer minichef & rewarder ownership to the controller
    await minichef.transferOwnership(miniChefController.address, true, false);
    await rewarder.transferOwnership(miniChefController.address, true, false);

    // Add strategist on the controller
    await miniChefController.connect(governance).addStrategist(strategist.address);

    return {alice, governance, strategist, pickle, reward, minichef, rewarder, miniChefController, jar1, jar2};
  };

  describe("Controller behaviour", () => {
    it("Should add new strategists", async () => {
      const {alice, governance, miniChefController} = await loadFixture(setupFixture);

      await miniChefController.connect(governance).addStrategist(alice.address);
      expect(await miniChefController.isStrategist(alice.address)).to.be.eq(true, "Strategist was not added");
    });

    it("Should remove strategists", async () => {
      const {strategist, governance, miniChefController} = await loadFixture(setupFixture);

      await miniChefController.connect(governance).removeStrategist(strategist.address);
      expect(await miniChefController.isStrategist(strategist.address)).to.be.eq(false, "Strategist was not removed");
    });

    it("Should transfer governance correctly", async () => {
      const {alice, governance, miniChefController} = await loadFixture(setupFixture);

      await miniChefController.connect(governance).setPendingGovernance(alice.address);
      await miniChefController.connect(alice).claimGovernance();
      expect(await miniChefController.governance()).to.be.eq(alice.address, "Governance was not transferred");
    });

    it("Should change chef/rewarder addresses correctly", async () => {
      const {alice, governance, miniChefController} = await loadFixture(setupFixture);

      await miniChefController.connect(governance).setMinichef(alice.address);
      expect(await miniChefController.MINICHEF()).to.be.eq(alice.address, "Minichef address was not changed");

      await miniChefController.connect(governance).setRewarder(alice.address);
      expect(await miniChefController.REWARDER()).to.be.eq(alice.address, "Rewarder address was not changed");
    });

    it("Only governance can change chef owner", async () => {
      const {alice, governance, miniChefController, minichef, rewarder} = await loadFixture(setupFixture);

      await miniChefController
        .connect(alice)
        .transferMinichefOwnership(alice.address)
        .catch(() => {});
      expect(await minichef.owner()).to.be.eq(miniChefController.address, "Non-governance changed minichef owner");

      await miniChefController
        .connect(alice)
        .transferRewarderOwnership(alice.address)
        .catch(() => {});
      expect(await rewarder.owner()).to.be.eq(miniChefController.address, "Non-governance changed rewarder owner");

      await miniChefController.connect(governance).transferMinichefOwnership(alice.address);
      await minichef.connect(alice).claimOwnership();
      expect(await minichef.owner()).to.be.eq(alice.address, "Governance failed to change minichef owner");

      await miniChefController.connect(governance).transferRewarderOwnership(alice.address);
      await rewarder.connect(alice).claimOwnership();
      expect(await rewarder.owner()).to.be.eq(alice.address, "Governance failed to change rewarder owner");
    });

    it("Should add multiple pools properly", async () => {
      const {strategist, miniChefController, minichef, rewarder, jar1, jar2} = await loadFixture(setupFixture);

      await miniChefController.connect(strategist).add([jar1.address, jar2.address], [10, 20]);
      expect(await minichef.lpToken(1)).to.be.eq(jar2.address, "LPs were not added properly on the minichef");
      expect((await minichef.poolInfo(1)).allocPoint).to.be.eq(20, "AllocPoints were not set properly on the minichef");
      expect(await rewarder.poolIds(1)).to.be.eq(1, "LPs were not added properly on the rewarder");
      expect((await rewarder.poolInfo(1)).allocPoint).to.be.eq(20, "AllocPoints were not set properly on the rewarder");
    });

    it("Should set emission rates correctly", async () => {
      const {strategist, miniChefController, minichef, rewarder} = await loadFixture(setupFixture);

      await miniChefController.connect(strategist).setPicklePerSecond(10001);
      expect(await minichef.picklePerSecond()).to.be.eq(
        BigNumber.from(10001),
        "Emission rate was not set properly on the minichef"
      );
      await miniChefController.connect(strategist).setRewardPerSecond(10002);
      expect(await rewarder.rewardPerSecond()).to.be.eq(
        BigNumber.from(10002),
        "Emission rate was not set properly on the rewarder"
      );
    });

    it("Should execute emergency properly", async () => {
      const {governance, miniChefController, minichef} = await loadFixture(setupFixture);

      // Renounce minichef ownership
      const signature = "transferOwnership(address,bool,bool)";
      const data = ethers.utils.defaultAbiCoder.encode(
        ["address", "bool", "bool"],
        [ethers.constants.AddressZero, true, true]
      );
      await miniChefController.connect(governance).execute(minichef.address, signature, data);
      expect(await minichef.owner()).to.be.eq(ethers.constants.AddressZero, "Emergency execute failed");
    });
  });
});
