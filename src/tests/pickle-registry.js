const { expect } = require("chai");

describe('PickleRegistry', () => {
  const ethers = hre.ethers;

  let factory;
  let registry;
  let governance;
  let curator;
  let other;
  let addresses;

  beforeEach(async () => {
    factory = await ethers.getContractFactory("PickleRegistry");
    [governance, curator, other, ...addresses] = await ethers.getSigners();
    registry = await factory.deploy();
  });

  describe('deployment', () => {
    it('sets proper governance', async () => {
      const actual = await registry.governance();
      expect(actual).to.equal(governance.address);
    });

    it('sets governance as a curator', async () => {
      const actual = await registry.curators(governance.address);
      expect(actual).to.equal(true);
    });

    it('has no other curators', async () => {
      const actual = await registry.curators(curator.address);
      expect(actual).to.equal(false);
    });
  });

  describe('setGovernance', () => {
    it('allows governance to update governance', async () => {
      await registry.setGovernance(curator.address);
      const actual = await registry.governance();
      expect(actual).to.equal(curator.address);
    });

    it('disallows others to update governance', async () => {
      await expect(registry.connect(curator).setGovernance(curator.address)).to.be.revertedWith("!governance");
    });
  });

  describe('addCurators', () => {
    it('allows governance to add curators', async () => {
      await registry.addCurators([curator.address, other.address]);
      const addedCurator = await registry.curators(curator.address);
      expect(addedCurator).to.equal(true);
      const addedOther = await registry.curators(other.address);
      expect(addedOther).to.equal(true);
    });

    it('allows curators to add curators', async () => {
      const foreign = addresses[0];
      await registry.addCurators([curator.address]);
      await registry.connect(curator).addCurators([other.address, foreign.address]);
      const addedOther = await registry.curators(other.address);
      expect(addedOther).to.equal(true);
      const addedForeign = await registry.curators(foreign.address);
      expect(addedForeign).to.equal(true);
    });

    it('disallows others to add curators', async () => {
      const foreign = addresses[0];
      await expect(registry.connect(curator).addCurators([other.address, foreign.address])).to.be.revertedWith("!curator");
    });
  });

  describe('removeCurators', () => {
    it('allows governance to remove curators', async () => {
      await registry.addCurators([curator.address, other.address]);
      await registry.removeCurators([other.address]);
      const addedCurator = await registry.curators(curator.address);
      expect(addedCurator).to.equal(true);
      const addedOther = await registry.curators(other.address);
      expect(addedOther).to.equal(false);
    });

    it('disallows curators to remove curators', async () => {
      await registry.addCurators([curator.address, other.address]);
      const addedCurator = await registry.curators(other.address);
      expect(addedCurator).to.equal(true);
      await expect(registry.connect(curator).removeCurators([other.address])).to.be.revertedWith("!governance");
    });

    it('disallows others to add curators', async () => {
      await expect(registry.connect(curator).removeCurators([other.address])).to.be.revertedWith("!governance");
    });

    it('disallows removal of governance from curators', async () => {
      await expect(registry.removeCurators([governance.address])).to.be.revertedWith("cannot remove governance");
    });
  });

  describe('registerVault', () => {
    it('allows curators to register a vault', async () => {
      const vault = addresses[0].address;
      await expect(registry.registerVault(vault)).to.emit(registry, 'RegisterVault').withArgs(vault);
    });

    it('disallows others to register a vault', async () => {
      const vault = addresses[0].address;
      await expect(registry.connect(curator).registerVault(vault)).to.be.revertedWith("!curator");
    });

    it('disallows duplicate vault registration', async () => {
      const vault = addresses[0].address;
      await registry.registerVault(vault);
      await expect(registry.registerVault(vault)).to.be.revertedWith("vault previously registered");
      await registry.promoteVault(vault);
      await expect(registry.registerVault(vault)).to.be.revertedWith("vault previously registered");
    });
  });

  describe('promoteVault', () => {
    it('allows curators to promote a vault', async () => {
      const vault = addresses[0].address;
      await registry.registerVault(vault);
      await expect(registry.promoteVault(vault)).to.emit(registry, 'PromoteVault').withArgs(vault);
    });

    it('disallows others to promote a vault', async () => {
      const vault = addresses[0].address;
      await expect(registry.connect(curator).promoteVault(vault)).to.be.revertedWith("!curator");
    });

    it('disallows non-existent vault promotion', async () => {
      const vault = addresses[0].address;
      await expect(registry.promoteVault(vault)).to.be.revertedWith("!development");
    });

    it('disallows production vault promotion', async () => {
      const vault = addresses[0].address;
      await registry.registerVault(vault);
      await registry.promoteVault(vault);
      await expect(registry.promoteVault(vault)).to.be.revertedWith("!development");
    });
  });

  describe('demoteVault', () => {
    it('allows curators to demote a vault', async () => {
      const vault = addresses[0].address;
      await registry.registerVault(vault);
      await registry.promoteVault(vault);
      await expect(registry.demoteVault(vault)).to.emit(registry, 'DemoteVault').withArgs(vault);
    });

    it('disallows others to demote a vault', async () => {
      const vault = addresses[0].address;
      await expect(registry.connect(curator).promoteVault(vault)).to.be.revertedWith("!curator");
    });

    it('disallows non-existent vault demotion', async () => {
      const vault = addresses[0].address;
      await expect(registry.demoteVault(vault)).to.be.revertedWith("!production");
    });

    it('disallows development vault demotion', async () => {
      const vault = addresses[0].address;
      await registry.registerVault(vault);
      await expect(registry.demoteVault(vault)).to.be.revertedWith("!production");
    });
  });

  describe('removeVault', () => {
    it('allows curators to remove a development vault', async () => {
      const vault = addresses[0].address;
      await registry.registerVault(vault);
      await expect(registry.removeVault(vault)).to.emit(registry, 'RemoveVault').withArgs(vault);
    });

    it('allows curators to remove a production vault', async () => {
      const vault = addresses[0].address;
      await registry.registerVault(vault);
      await registry.promoteVault(vault);
      await expect(registry.removeVault(vault)).to.emit(registry, 'RemoveVault').withArgs(vault);
    });

    it('disallows others to demote a vault', async () => {
      const vault = addresses[0].address;
      await expect(registry.connect(curator).removeVault(vault)).to.be.revertedWith("!curator");
    });
  });
});
