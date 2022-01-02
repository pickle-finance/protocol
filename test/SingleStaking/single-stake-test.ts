/* eslint-disable no-undef */
const { ethers, network } = require("hardhat");
import chai from "chai";
import { expect } from "chai";
import { BigNumber } from "@ethersproject/bignumber";
import { 
   returnController, 
   overwriteTokenAmount, 
   increaseBlock, 
   returnSigner, 
   fastForwardAWeek, 
   findSlot, 
   getEnvVar
} from "../utils/helpers";
import { setupSigners, snowballAddr, treasuryAddr} from "../utils/static";
import { 
   Contract, 
   ContractFactory,
   Signer 
} from "ethers";

const GlobeABI = require('./abis/GlobeABI.json');
const StratABI = require('./abis/StratABI.json');

export function doSingleStakeTest (
    name: string,
    assetAddr: string,
    snowglobeAddr = "",
    strategyAddr = "",
    controller = "main",
    globeABI = GlobeABI,
    stratABI = StratABI,
    txnAmt = "250000000000000000000000",
) {

    const walletAddr = getEnvVar('WALLET_ADDR');
    const slot = findSlot(assetAddr);
    let assetContract: Contract;
    let controllerContract: Contract;
    let governanceSigner: Signer;
    let strategistSigner: Signer;
    let controllerSigner: Signer;
    let walletSigner: Signer;
    let timelockSigner: Signer;
    let globeContract: Contract;
    let strategyContract: Contract;
    let strategyBalance: string;
    let controllerAddr: string;
    let snapshotId: string;
    
    describe("Folding Strategy tests for: " + name, async () => {

        //These reset the state after each test is executed 
        beforeEach(async () => {
            snapshotId = await ethers.provider.send('evm_snapshot');
        });
        afterEach(async () => {
            await ethers.provider.send('evm_revert', [snapshotId]);
        });

        before(async () => {
            const strategyName = `Strategy${name}`;
            const snowglobeName = `SnowGlobe${name}`;

            await network.provider.send('hardhat_impersonateAccount', [wallet_addr]);
            console.log(`impersonating account: ${wallet_addr}`);
            walletSigner = ethers.provider.getSigner(wallet_addr);
            [timelockSigner, strategistSigner, governanceSigner] = await setupSigners();

            controllerAddr = returnController(controller);
            controllerSigner = await returnSigner(controllerAddr);
            walletSigner = await returnSigner(walletAddr);

            await overwriteTokenAmount(assetAddr, walletAddr, txnAmt, slot);

            assetContract = await ethers.getContractAt("ERC20", assetAddr, walletSigner);
            controllerContract = await ethers.getContractAt("ControllerV4", controllerAddr, governanceSigner);

            //If snowglobe address not supplied then we should deploy and setup a new snowglobe
            if (snowglobeAddr == "") {
                const globeFactory = await ethers.getContractFactory(snowglobeName);
                globeContract = await globeFactory.deploy(assetAddr, governanceSigner.getAddress(), timelockSigner.getAddress(), controllerAddr);
                await controllerContract.setGlobe(assetAddr, globeContract.address);
                snowglobeAddr = globeContract.address;
            }
            else {
                globeContract = new ethers.Contract(snowglobeAddr, globeABI, governanceSigner);
            }
            //If strategy address not supplied then we should deploy and setup a new strategy
            if (!strategy_addr) {
                console.log(`deploying strategy ${strategyName}`);
                const stratFactory = await ethers.getContractFactory(strategyName);
                // Now we can deploy the new strategy
                console.log(`${governanceSigner._address}, ${strategistSigner._address}, ${controller_addr}, ${timelock_addr}`);
                Strategy = await stratFactory.connect(walletSigner).deploy(governanceSigner._address, strategistSigner._address, controller_addr, timelock_addr);
                console.log(`deployed new strategy at ${Strategy.address}`);
                asset_addr = await Strategy.want();
                console.log(`asset address: ${asset_addr}`);
                strategy_addr = Strategy.address;
                
                const approveStrategy = await Controller.connect(timelockSigner).approveStrategy(asset_addr,strategy_addr);
                const tx_approveStrategy = await approveStrategy.wait(1);
                if (!tx_approveStrategy.status) {
                    console.error("Error approving the strategy for: ",name);
                    return;
                }
                console.log("Approved Strategy in the Controller for: ",name);

                // Now we can deploy the new strategy
                strategyContract = await stratFactory.deploy(governanceSigner.getAddress(), strategistSigner.getAddress(), controllerAddr, timelockSigner.getAddress());
                strategyAddr = strategyContract.address;
                // console.log("\tDeployed strategy address is: " + strategyAddr);
                await controllerContract.connect(timelockSigner).approveStrategy(assetAddr, strategyAddr);
                await controllerContract.connect(timelockSigner).setStrategy(assetAddr, strategyAddr);
            } else {            
                Strategy = new ethers.Contract(strategy_addr, stratABI, governanceSigner);
                let timelock_addr = await Strategy.timelock();
                timelockSigner = await returnSigner(timelock_addr);
            }
            asset_addr = await Strategy.want();
            
            if (!snowglobe_addr) {
                snowglobe_addr = await Controller.globes(asset_addr);
                console.log("controller_addr: ",controller_addr);
                console.log("snowglobe_addr: ",snowglobe_addr);
                if (snowglobe_addr != 0) {
                    SnowGlobe = new ethers.Contract(snowglobe_addr, globeABI, governanceSigner);
                    console.log(`connected to snowglobe at ${SnowGlobe.address}`);
                }
                else {
                    const globeFactory = await ethers.getContractFactory(snowglobeName);
                    SnowGlobe = await globeFactory.deploy(asset_addr, governanceSigner._address, timelockSigner._address, controller_addr);
                    console.log(`deployed new snowglobe at ${SnowGlobe.address}`);
                    const setGlobe = await Controller.setGlobe(asset_addr, SnowGlobe.address);
                    const tx_setGlobe = await setGlobe.wait(1);
                    if (!tx_setGlobe.status) {
                        console.error("Error setting the globe for: ",name);
                        return;
                    }
                    console.log("Set Globe in the Controller for: ",name);
                    snowglobe_addr = SnowGlobe.address;
                }
            }
            else {
                SnowGlobe = new ethers.Contract(snowglobe_addr, globeABI, governanceSigner);
                console.log(`connected to snowglobe at ${SnowGlobe.address}`);
            }
            const earn = await SnowGlobe.earn();
            const tx_earn = await earn.wait(1);
            if (!tx_earn.status) {
                console.error("Error calling earn in the Snowglobe for: ",name);
                return;
            }
            console.log("Called earn in the Snowglobe for: ",name);

            if (fold) {
                // Now leverage to max
                const leverage = await Strategy.connect(governanceSigner).leverageToMax();
                const tx_leverage = await leverage.wait(1);
                if (!tx_leverage.status) {
                    console.error("Error leveraging the strategy for: ",name);
                    return;
                }
                console.log("Leveraged the strategy for: ",name);
            }

            /* Gauges */
            const gaugeproxy_ABI = [{"type":"constructor","stateMutability":"nonpayable","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"contract IceQueen"}],"name":"MASTER","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"contract IERC20"}],"name":"SNOWBALL","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"contract IERC20"}],"name":"SNOWCONE","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"contract IERC20"}],"name":"TOKEN","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"acceptGovernance","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"addGauge","inputs":[{"type":"address","name":"_token","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"collect","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"deposit","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"distribute","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"gauges","inputs":[{"type":"address","name":"","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"getGauge","inputs":[{"type":"address","name":"_token","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"governance","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"length","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"pendingGovernance","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"pid","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"poke","inputs":[{"type":"address","name":"_owner","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"reset","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setGovernance","inputs":[{"type":"address","name":"_governance","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setPID","inputs":[{"type":"uint256","name":"_pid","internalType":"uint256"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"tokenVote","inputs":[{"type":"address","name":"","internalType":"address"},{"type":"uint256","name":"","internalType":"uint256"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address[]","name":"","internalType":"address[]"}],"name":"tokens","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"totalWeight","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"usedWeights","inputs":[{"type":"address","name":"","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"vote","inputs":[{"type":"address[]","name":"_tokenVote","internalType":"address[]"},{"type":"uint256[]","name":"_weights","internalType":"uint256[]"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"votes","inputs":[{"type":"address","name":"","internalType":"address"},{"type":"address","name":"","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"weights","inputs":[{"type":"address","name":"","internalType":"address"}]}];
            const gaugeproxy_addr = "0x215D5eDEb6A6a3f84AE9d72962FEaCCdF815BF27";

            const GaugeProxy = new ethers.Contract(gaugeproxy_addr, gaugeproxy_ABI, governanceSigner);
            const gauge_governance_addr = await GaugeProxy.governance();
            console.log(`gaugeProxy governance: ${gauge_governance_addr}`);
            const gaugeGovernanceSigner = await returnSigner(gauge_governance_addr);
            const gauge = await GaugeProxy.getGauge(SnowGlobe.address);
            if (gauge == 0) {
                const addGauge = await GaugeProxy.connect(gaugeGovernanceSigner).addGauge(SnowGlobe.address);
                const tx_addGauge = await addGauge.wait(1);
                if (!tx_addGauge.status) {
                    console.error(`Error adding the gauge for: ${name}`);
                    return;
                }
                console.log(`addGauge for ${name}`);
            }

            assetContract = await ethers.getContractAt("ERC20", asset_addr, walletSigner);
            console.log(`${asset_addr}, ${wallet_addr}, ${txnAmt}, ${slot}`);
            await overwriteTokenAmount(asset_addr, wallet_addr, txnAmt, slot);
        });

        const harvester = async () => {
            await overwriteTokenAmount(asset_addr, wallet_addr, txnAmt, slot);
            let amt = await assetContract.connect(walletSigner).balanceOf(wallet_addr);

            let balBefore = await assetContract.connect(walletSigner).balanceOf(snowglobe_addr);
            
            await assetContract.connect(walletSigner).approve(snowglobe_addr, amt);
            await SnowGlobe.connect(walletSigner).deposit(amt);
            await SnowGlobe.connect(walletSigner).earn();

            let userBal = await assetContract.connect(walletSigner).balanceOf(wallet_addr);
            expect(userBal).to.be.equals(BigNumber.from("0x0"));
            let balAfter = await assetContract.connect(walletSigner).balanceOf(snowglobe_addr);
            expect(balBefore).to.be.lt(balAfter);

            await fastForwardAWeek();

            let harvestable = await Strategy.getHarvestable();
            console.log("\tHarvestable, pre harvest: ",harvestable.toString());
            let initialBalance = await Strategy.balanceOf();
            await Strategy.connect(walletSigner).harvest();
            await increaseBlock(2);
            harvestable = await Strategy.getHarvestable();
            console.log("\tHarvestable, post harvest: ",harvestable.toString());

            return [amt, initialBalance];
        };

        it("user wallet contains asset balance", async () => {
            let BNBal = await assetContract.balanceOf(await walletSigner.getAddress());
            const BN = ethers.BigNumber.from(txnAmt)._hex.toString();
            expect(BNBal).to.be.equals(BN);
        });

        it("Globe initialized with zero balance for user", async () => {
            let BNBal = await globeContract.balanceOf(walletSigner.getAddress());
            expect(BNBal).to.be.equals(BigNumber.from("0x0"));
        });

        it("Should be able to be configured correctly", async () => {
            expect(await Controller.globes(asset_addr)).to.contains(snowglobe_addr);
            //expect(await Controller.strategies(asset_addr)).to.be.equals(strategy_addr);
        });

        it("Should be able to deposit/withdraw money into globe", async () => {
            await assetContract.approve(snowglobe_addr, "2500000000000000000000000000");
            let balBefore = await assetContract.connect(walletSigner).balanceOf(snowglobe_addr);
            await SnowGlobe.connect(walletSigner).depositAll();

            let userBal = await assetContract.connect(walletSigner).balanceOf(wallet_addr);
            expect(userBal).to.be.equals(BigNumber.from("0x0"));

            let balAfter = await assetContract.connect(walletSigner).balanceOf(snowglobe_addr);
            expect(balBefore).to.be.lt(balAfter);

            await SnowGlobe.connect(walletSigner).withdrawAll();

            userBal = await assetContract.connect(walletSigner).balanceOf(walletAddr);
            expect(userBal).to.be.gt(0);
        });

        it("Harvests should make some money!", async () => {
            let initialBalance;
            [, initialBalance] = await harvester();

            let newBalance = await Strategy.balanceOf();
            console.log(`initial balance: ${initialBalance}`);
            console.log(`new balance: ${newBalance}`);
            expect(newBalance).to.be.gt(initialBalance);
        });

        it("Strategy loaded with initial balance", async () => {
            await assetContract.approve(snowglobe_addr,"2500000000000000000000000000");
            await SnowGlobe.connect(walletSigner).depositAll();

            await SnowGlobe.connect(walletSigner).earn();

            strategyBalance = await Strategy.balanceOf();
            expect(strategyBalance).to.not.be.equals(BigNumber.from("0x0"));
        });

        it("Users should earn some money!", async () => {
            await overwriteTokenAmount(asset_addr, wallet_addr, txnAmt, slot);
            let amt = await assetContract.connect(walletSigner).balanceOf(wallet_addr);

            await assetContract.connect(walletSigner).approve(snowglobe_addr, amt);
            await SnowGlobe.connect(walletSigner).deposit(amt);
            await SnowGlobe.connect(walletSigner).earn();

            await fastForwardAWeek();

            await Strategy.connect(walletSigner).harvest();
            await increaseBlock(1);

            await SnowGlobe.connect(walletSigner).withdrawAll();
            let newAmt = await assetContract.connect(walletSigner).balanceOf(wallet_addr);

            expect(amt).to.be.lt(newAmt);
        });

        // Issue raised at: https://github.com/Snowball-Finance/protocol/issues/76
        it("should take no commission when fees not set", async () =>{
            await overwriteTokenAmount(asset_addr,wallet_addr,txnAmt,slot);
            let amt = await assetContract.connect(walletSigner).balanceOf(wallet_addr);

            await assetContract.connect(walletSigner).approve(snowglobe_addr,amt);
            await SnowGlobe.connect(walletSigner).deposit(amt);
            await SnowGlobe.connect(walletSigner).earn();

            await fastForwardAWeek();

            // Set PerformanceTreasuryFee
            await Strategy.connect(timelockSigner).setPerformanceTreasuryFee(0);

            // Set KeepPNG
            await Strategy.connect(timelockSigner).setKeep(0);
            let snobContract = await ethers.getContractAt("ERC20",snowball_addr,walletSigner);

            const globeBefore = await SnowGlobe.balance();
            const treasuryBefore = await assetContract.connect(walletSigner).balanceOf(treasury_addr);
            const snobBefore = await snobContract.balanceOf(treasury_addr);

            await Strategy.connect(walletSigner).harvest();
            await increaseBlock(1);
            const globeAfter = await SnowGlobe.balance();
            const treasuryAfter = await assetContract.connect(walletSigner).balanceOf(treasury_addr);
            const snobAfter = await snobContract.balanceOf(treasury_addr);
            const earnt = globeAfter.sub(globeBefore);
            const earntTTreasury = treasuryAfter.sub(treasuryBefore);
            const snobAccrued = snobAfter.sub(snobBefore);
            // console.log("\t💸Snowglobe profit after harvest: ", earnt.toString());
            // console.log("\t💸Treasury profit after harvest: ", earntTTreasury.toString());
            // console.log("\t💸Snowball token accrued : " + snobAccrued.toString());
            expect(snobAccrued).to.be.lt(1);
            expect(earntTTreasury).to.be.lt(1);
        }); 

        it("should take some commission when fees are set", async () => {
            // Set PerformanceTreasuryFee
            await Strategy.connect(timelockSigner).setPerformanceTreasuryFee(0);
            // Set KeepPNG
            await Strategy.connect(timelockSigner).setKeep(1000);

            let snobContract = await ethers.getContractAt("ERC20", snowball_addr, walletSigner);

            const globeBefore = await SnowGlobe.balance();
            const treasuryBefore = await assetContract.connect(walletSigner).balanceOf(treasury_addr);
            const snobBefore = await snobContract.balanceOf(treasury_addr);
            console.log("snobBefore: ",snobBefore.toString());

            let initialBalance;
            [, initialBalance] = await harvester();

            let newBalance = await Strategy.balanceOf();
            console.log(`initial balance: ${initialBalance}`);
            console.log(`new balance: ${newBalance}`);

            const globeAfter = await SnowGlobe.balance();
            const treasuryAfter = await assetContract.connect(walletSigner).balanceOf(treasury_addr);
            const snobAfter = await snobContract.balanceOf(treasury_addr);
            console.log("snobAfter: ",snobAfter.toString());
            const earnt = globeAfter.sub(globeBefore);
            const earntTTreasury = treasuryAfter.sub(treasuryBefore);
            const snobAccrued = snobAfter.sub(snobBefore);
            // console.log("\t💸Snowglobe profit after harvest: ", earnt.toString());
            // console.log("\t💸Treasury profit after harvest: ", earntTTreasury.toString());
            // console.log("\t💸Snowball token accrued : " + snobAccrued);
            expect(snobAccrued).to.be.gt(1);
            // expect(earntTTreasury).to.be.gt(BigNumber.from(1));
        });

    });

};
