const hre = require("hardhat");
var chaiAsPromised = require("chai-as-promised");
const StrategyCurveAlusd3Crv = hre.artifacts.require("StrategyAlusd3Crv");
const PickleJarSymbiotic = hre.artifacts.require("PickleJarSymbiotic");
const ControllerV5 = hre.artifacts.require("ControllerV5");
const ProxyAdmin = hre.artifacts.require("ProxyAdmin");
const AdminUpgradeabilityProxy = hre.artifacts.require("AdminUpgradeabilityProxy");

const {assert} = require("chai").use(chaiAsPromised);
const {time} = require("@openzeppelin/test-helpers");

const unlockAccount = async (address) => {
    await hre.network.provider.send("hardhat_impersonateAccount", [address]);
    return hre.ethers.provider.getSigner(address);
};

const toWei = (ethAmount) => {
    return hre.ethers.constants.WeiPerEther.mul(hre.ethers.BigNumber.from(ethAmount));
};

describe("StrategyCurveAlusd3Crv Unit test", () => {
    let strategy, pickleJar;
    let proxyAdmin, controller;
    const want = "0x43b4FdFD4Ff969587185cDB6f0BD875c5Fc83f8c";
    let alusd_3crv, alusd_3crv_whale;
    let deployer, alice, bob;
    let alcx,
        alcx_addr = "0xdbdb4d16eda451d0503b854cf79d55697f90c8df";
    let governance, strategist, devfund, treasury, timelock;
    let preTestSnapshotID;

    before("Deploy contracts", async () => {
        [governance, devfund, treasury] = await web3.eth.getAccounts();
        const signers = await hre.ethers.getSigners();
        deployer = signers[0];
        alice = signers[3];
        bob = signers[4];
        john = signers[5];

        strategist = governance;
        timelock = governance;

        proxyAdmin = await ProxyAdmin.new();
        console.log("ProxyAdmin address =====> ", proxyAdmin.address);
        const controllerImplement = await ControllerV5.new();
        
        console.log("Controller implementation =====> ", controllerImplement.address);
        const controllerProxy = await AdminUpgradeabilityProxy.new(controllerImplement.address, proxyAdmin.address, []);

        controller = await hre.ethers.getContractAt("ControllerV5", controllerProxy.address);

        await controller.initialize(governance, strategist, timelock, devfund, treasury);
        console.log("controller is deployed at =====> ", controller.address);

        strategy = await StrategyCurveAlusd3Crv.new(governance, strategist, controller.address, timelock);
        console.log("Strategy is deployed at =====> ", strategy.address);

        pickleJar = await PickleJarSymbiotic.new(want, alcx_addr, governance, timelock, controller.address);
        console.log("pickleJar is deployed at =====> ", pickleJar.address);

        await controller.setJar(want, pickleJar.address, {from: governance});
        await controller.approveStrategy(want, strategy.address, {
            from: governance,
        });
        await controller.setStrategy(want, strategy.address, {from: governance});

        await strategy.setKeepAlcx("2000", { from: governance });
        
        const whaleAddr = "0xbFeb87721f0076e6F8c4EC2DaBdc9E2F18472E7b";
        
        alusd_3crv_whale = await unlockAccount(whaleAddr);
        alusd_3crv = await hre.ethers.getContractAt("ERC20", want);
        alcx = await hre.ethers.getContractAt("ERC20", alcx_addr);

        alusd_3crv.connect(alusd_3crv_whale).transfer(alice.address, toWei(50));
        assert.equal((await alusd_3crv.balanceOf(alice.address)).toString(), toWei(50).toString());
        alusd_3crv.connect(alusd_3crv_whale).transfer(bob.address, toWei(50));
        assert.equal((await alusd_3crv.balanceOf(bob.address)).toString(), toWei(50).toString());
        alusd_3crv.connect(alusd_3crv_whale).transfer(john.address, toWei(50));
        assert.equal((await alusd_3crv.balanceOf(john.address)).toString(), toWei(50).toString());
    });

    beforeEach(async () => {
        preTestSnapshotID = await hre.network.provider.send("evm_snapshot");
    });

    afterEach(async () => {
        await hre.network.provider.send("evm_revert", [preTestSnapshotID]);
    });
    
    it("Should harvest the reward correctly", async () => {
        console.log("\n---------------------------Alice deposit---------------------------------------\n");
        await alusd_3crv.connect(alice).approve(pickleJar.address, toWei(50));
        await pickleJar.deposit(toWei(50), {from: alice.address});
        console.log("alice pToken balance =====> ", (await pickleJar.balanceOf(alice.address)).toString());
        //await pickleJar.earn({ from: alice.address });

        await harvest();

        console.log("\n---------------------------Bob deposit---------------------------------------\n");
        await alusd_3crv.connect(bob).approve(pickleJar.address, toWei(30));
        await pickleJar.deposit(toWei(30), {from: bob.address});
        console.log("bob pToken balance =====> ", (await pickleJar.balanceOf(bob.address)).toString());
        await pickleJar.earn({ from: bob.address });

        await time.increase(60 * 60 * 24 * 7);

        console.log("\n---------------------------John deposit---------------------------------------\n");
        await alusd_3crv.connect(john).approve(pickleJar.address, toWei(50));
        await pickleJar.deposit(toWei(50), {from: john.address});
        console.log("bob pToken balance =====> ", (await pickleJar.balanceOf(john.address)).toString());

        await harvest();

        console.log("\n---------------------------Alice withdraw---------------------------------------\n");
        console.log("Reward balance of strategy ====> ", (await alcx.balanceOf(strategy.address)).toString());
        let _alcx_before = await alcx.balanceOf(alice.address);
        console.log("Alice alcx balance before =====> ", _alcx_before.toString());

        // console.log("\nPending reward before withdraw ====> ", (await strategy.pendingReward()).toString());

        await pickleJar.withdrawAll({from: alice.address});

        let _alcx_after = await alcx.balanceOf(alice.address);
        console.log("Alice alcx balance after =====> ", _alcx_after.toString());

        assert.equal(_alcx_after.gt(_alcx_before), true);

        console.log("\nPending reward after all withdrawal ====> ", (await strategy.pendingReward()).toString());

        await time.increase(60 * 60 * 24 * 3);

        console.log("\n---------------------------Alice Redeposit---------------------------------------\n");
        await alusd_3crv.connect(alice).approve(pickleJar.address, toWei(50));
        await pickleJar.deposit(toWei(50), {from: alice.address});
        //await pickleJar.earn({ from: alice.address });
        console.log("alice pToken balance =====> ", (await pickleJar.balanceOf(alice.address)).toString());

        await time.increase(60 * 60 * 24 * 4);

        console.log("\n---------------------------Bob withdraw---------------------------------------\n");

        console.log("Reward balance of strategy ====> ", (await alcx.balanceOf(strategy.address)).toString());
        _alcx_before = await alcx.balanceOf(bob.address);
        console.log("Bob alcx balance before =====> ", _alcx_before.toString());

        await pickleJar.withdrawAll({from: bob.address});

        _alcx_after = await alcx.balanceOf(bob.address);
        console.log("Bob alcx balance after =====> ", (await alcx.balanceOf(bob.address)).toString());
        assert.equal(_alcx_after.gt(_alcx_before), true);

        console.log("\nPending reward after all withdrawal ====> ", (await strategy.pendingReward()).toString());

        console.log("\n---------------------------John withdraw---------------------------------------\n");
        console.log("Reward balance of strategy ====> ", (await alcx.balanceOf(strategy.address)).toString());

        _alcx_before = await alcx.balanceOf(john.address);
        console.log("John alcx balance before =====> ", _alcx_before.toString());

        await pickleJar.withdrawAll({from: john.address});

        _alcx_after = await alcx.balanceOf(john.address);
        console.log("John alcx balance after =====> ", (await alcx.balanceOf(john.address)).toString());
        assert.equal(_alcx_after.gt(_alcx_before), true);
        console.log("\nPending reward after all withdrawal ====> ", (await strategy.pendingReward()).toString());

        console.log("\n---------------------------Alice second withdraw---------------------------------------\n");
        _alcx_before = await alcx.balanceOf(alice.address);
        console.log("Alice alcx balance before =====> ", _alcx_before.toString());

        await pickleJar.withdrawAll({from: alice.address});

        _alcx_after = await alcx.balanceOf(alice.address);
        console.log("Alice alcx balance after =====> ", _alcx_after.toString());

        assert.equal(_alcx_after.gt(_alcx_before), true);
        console.log("\nPending reward after all withdrawal ====> ", (await strategy.pendingReward()).toString());
        console.log("\nPickle Jar Pending reward after all withdrawal ====> ", (await pickleJar.pendingReward()).toString());
    });

    it("Should withdraw the want correctly", async () => {
        console.log("\n---------------------------Alice deposit---------------------------------------\n");
        await alusd_3crv.connect(alice).approve(pickleJar.address, toWei(50));
        await pickleJar.deposit(toWei(50), {from: alice.address});
        console.log("alice pToken balance =====> ", (await pickleJar.balanceOf(alice.address)).toString());

        await harvest();

        console.log("\n---------------------------Bob deposit---------------------------------------\n");
        await alusd_3crv.connect(bob).approve(pickleJar.address, toWei(30));
        await pickleJar.deposit(toWei(30), {from: bob.address});
        console.log("bob pToken balance =====> ", (await pickleJar.balanceOf(bob.address)).toString());
        await pickleJar.earn({from: bob.address});
        await harvest();

        console.log("\n---------------------------Alice withdraw---------------------------------------\n");

        let _jar_before = await alusd_3crv.balanceOf(pickleJar.address);
        await controller.withdrawAll(alusd_3crv.address, {from: governance});
        let _jar_after = await alusd_3crv.balanceOf(pickleJar.address);

        let _alcx_before = await alcx.balanceOf(alice.address);
        console.log("Alice alcx balance before =====> ", _alcx_before.toString());

        await pickleJar.withdrawAll({from: alice.address});

        let _alcx_after = await alcx.balanceOf(alice.address);
        console.log("Alice alcx balance after =====> ", _alcx_after.toString());

        console.log("\n---------------------------Bob withdraw---------------------------------------\n");

        _alcx_before = await alcx.balanceOf(bob.address);
        console.log("Bob alcx balance before =====> ", _alcx_before.toString());

        _jar_before = await alusd_3crv.balanceOf(pickleJar.address);

        await controller.withdrawAll(alusd_3crv.address, {from: governance});

        _jar_after = await alusd_3crv.balanceOf(pickleJar.address);

        await pickleJar.withdrawAll({from: bob.address});

        _alcx_after = await alcx.balanceOf(bob.address);
        console.log("Bob alcx balance after =====> ", (await alcx.balanceOf(bob.address)).toString());
        assert.equal(_alcx_after.gt(_alcx_before), true);
        console.log("\nStrategy Pending reward after all withdrawal ====> ", (await strategy.pendingReward()).toString());
        console.log("\nPickle Jar Pending reward after all withdrawal ====> ", (await pickleJar.pendingReward()).toString());
    });

    const harvest = async () => {
        await time.increase(60 * 60 * 24 * 15); //15 days
        const _balance = await strategy.balanceOfPool();
        console.log("Deposited amount of strategy ===> ", _balance.toString());

        let _alcx = await strategy.getHarvestable();
        console.log("Alusd3Crv Farm harvestable of strategy of the first harvest ===> ", _alcx.toString());
        let _alcx2 = await strategy.getAlcxFarmHarvestable();
        console.log("Alcx Farm harvestable of strategy of the first harvest ===> ", _alcx2.toString());

        await strategy.harvest({from: governance});
        await time.increase(60 * 60 * 24 * 15);

        _alcx = await strategy.getHarvestable();
        console.log("Alusd3Crv Farm harvestable of strategy of the second harvest ===> ", _alcx.toString());

        _alcx2 = await strategy.getAlcxFarmHarvestable();
        console.log("Alcx Farm harvestable of strategy of the second harvest ===> ", _alcx2.toString());

        await strategy.harvest({from: governance});
    };
});
