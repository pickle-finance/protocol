/* eslint-disable no-undef */
const { ethers, network } = require("hardhat");

import { BigNumber } from "@ethersproject/bignumber";
import chaiModule from "chai";
import chaiAsPromised = require("chai-as-promised");
import { expect } from "chai";
import { 
   setupSigners, 
   snowballAddr, 
   treasuryAddr 
} from "../utils/static";
import { 
   increaseTime, 
   overwriteTokenAmount, 
   increaseBlock
} from "../utils/helpers";

export function doLPStrategyTest (name, _snowglobeAddr, _controllerAddr, globeABI, stratABI, _slot) {

    const wallet_addr = process.env.WALLET_ADDR;
    let assetContract,controllerContract;
    let governanceSigner, strategistSigner, timelockSigner;
    let globeContract, strategyContract;
    let strategyBalance, asset_addr, strategy_addr;
    let snowglobe_addr = _snowglobe_addr ? _snowglobe_addr : "";
    let controller_addr = _controller_addr ? _controller_addr : "0xf7B8D9f8a82a7a6dd448398aFC5c77744Bd6cb85";

    const txnAmt = "25000000000000000000000";
    const slot = _slot ? _slot : 1;

    describe("LP Strategy tests for: "+name, async () => {

        //These reset the state after each test is executed 
        beforeEach(async () => {
            snapshotId = await ethers.provider.send('evm_snapshot');
        });
  
        afterEach(async () => {
            await ethers.provider.send('evm_revert', [snapshotId]);
        });

        before( async () => {
            const strategyName = `Strategy${name}`;
            const snowglobeName = `SnowGlobe${name}`;
            await network.provider.send('hardhat_impersonateAccount', [wallet_addr]);
            walletSigner = ethers.provider.getSigner(wallet_addr);
            [timelockSigner,strategistSigner,governanceSigner] = await setupSigners();

            controllerContract = await ethers.getContractAt("ControllerV4", controller_addr, governanceSigner);
            
            //The Strategy address will not be supplied. We should deploy and setup a new strategy
            const stratFactory = await ethers.getContractFactory(strategyName);
            // Now we can deploy the new strategy
            strategyContract = await stratFactory.deploy(governanceSigner._address, strategistSigner._address,controller_addr,timelockSigner._address);
            asset_addr = await strategyContract.want();
            strategy_addr = strategyContract.address;
            // console.log(`\tDeployed ${strategyName} address is: ${strategy_addr}`);
            await controllerContract.connect(timelockSigner).approveStrategy(asset_addr,strategy_addr);
            
            /* Harvest old strategy */
            const oldStrategy_addr = await controllerContract.strategies(asset_addr);
            const oldStrategy = new ethers.Contract(oldStrategy_addr, stratABI, governanceSigner);
            const harvest = await oldStrategy.harvest();
            const tx_harvest = await harvest.wait(1);
            if (!tx_harvest.status) {
                console.error("Error harvesting the old strategy for: ",name);
                return;
            }
            console.log("Harvested the old strategy for: ",name);

            await controllerContract.connect(timelockSigner).setStrategy(asset_addr,strategy_addr);

            if (!snowglobe_addr) {
                snowglobe_addr = await controllerContract.globes(asset_addr);
                console.log("controller_addr: ",controller_addr);
                console.log("snowglobe_addr: ",snowglobe_addr);
                if (snowglobe_addr != 0) {
                    console.log("here");
                    globeContract = new ethers.Contract(snowglobe_addr, globeABI, governanceSigner);
                }
                else {
                    const globeFactory = await ethers.getContractFactory(snowglobeName);
                    globeContract = await globeFactory.deploy(asset_addr, governanceSigner._address, timelockSigner._address, controller_addr);
                    await controllerContract.setGlobe(asset_addr, globeContract.address);
                    snowglobe_addr = globeContract.address;
                }
            }
            else {
                globeContract = new ethers.Contract(snowglobe_addr, globeABI, governanceSigner);
            }

            /* Earn */
            const earn = await globeContract.earn();
            const tx_earn = await earn.wait(1);
            if (!tx_earn.status) {
                console.error("Error calling earn in the Snowglobe for: ",name);
                return;
            }
            console.log("Called earn in the Snowglobe for: ",name);

            await overwriteTokenAmount(asset_addr,wallet_addr,txnAmt,slot);
            assetContract = await ethers.getContractAt("ERC20",asset_addr,walletSigner);
            
            await strategyContract.connect(governanceSigner).whitelistHarvester(wallet_addr);
        });

        const harvester = async () => {
            await overwriteTokenAmount(asset_addr,wallet_addr,txnAmt,slot);
            let amt = await assetContract.connect(walletSigner).balanceOf(wallet_addr);

            await assetContract.connect(walletSigner).approve(snowglobe_addr,amt);
            let balBefore = await assetContract.connect(walletSigner).balanceOf(snowglobe_addr);
            await globeContract.connect(walletSigner).depositAll();
            
            let userBal = await assetContract.connect(walletSigner).balanceOf(wallet_addr);
            expect(userBal).to.be.equals(BigNumber.from("0x0"));
    
            let balAfter = await assetContract.connect(walletSigner).balanceOf(snowglobe_addr);
            expect(balBefore).to.be.lt(balAfter);
            await globeContract.connect(walletSigner).earn();
            await increaseTime(60 * 60 * 24 * 30);
            await increaseBlock(60 * 60);

            let harvestable = await strategyContract.getHarvestable();
            console.log("\tHarvestable, pre harvest: ",harvestable.toString());
            let initialBalance = await strategyContract.balanceOf();
            await strategyContract.connect(walletSigner).harvest();
            await increaseBlock(1);
            harvestable = await strategyContract.getHarvestable();
            console.log("\tHarvestable, post harvest: ",harvestable.toString());

            return [amt, initialBalance];
        };
    
        it("user wallet contains asset balance", async () =>{
            let BNBal = await assetContract.balanceOf(wallet_addr);
            console.log(`The balance of BNBal is: ${BNBal}`); 

            const BN = ethers.BigNumber.from(txnAmt)._hex.toString();
            console.log(`The balance of BN is: ${BN}`); 

            expect(BNBal).to.be.equals(BN);
        });
    
        it("Globe initialized with zero balance for user", async () =>{
            let BNBal = await globeContract.balanceOf(walletSigner._address);
            expect(BNBal).to.be.equals(BigNumber.from("0x0"));
        });
    
        it("Should be able to be configured correctly", async () => {
            expect(await controllerContract.globes(asset_addr)).to.be.equals(snowglobe_addr);
            expect(await controllerContract.strategies(asset_addr)).to.be.equals(strategy_addr);
        });
    
        it("Should be able to deposit/withdraw money into globe", async () => {
            await assetContract.approve(snowglobe_addr,"2500000000000000000000000000");
            let balBefore = await assetContract.connect(walletSigner).balanceOf(snowglobe_addr);
            await globeContract.connect(walletSigner).depositAll();
            
            let userBal = await assetContract.connect(walletSigner).balanceOf(wallet_addr);
            expect(userBal).to.be.equals(BigNumber.from("0x0"));
    
            let balAfter = await assetContract.connect(walletSigner).balanceOf(snowglobe_addr);
            expect(balBefore).to.be.lt(balAfter);
    
            await globeContract.connect(walletSigner).withdrawAll();
            
            userBal = await assetContract.connect(walletSigner).balanceOf(wallet_addr);
            expect(userBal).to.be.gt(BigNumber.from("0x0"));
        });
    
        it("Harvests should make some money!", async () => {
            let initialBalance;
            [, initialBalance] = await harvester();

            let newBalance = await strategyContract.balanceOf();
            expect(newBalance).to.be.gt(initialBalance);
        });

        it("Strategy loaded with initial balance", async () =>{
            await assetContract.approve(snowglobe_addr,"2500000000000000000000000000");
            let balBefore = await assetContract.connect(walletSigner).balanceOf(snowglobe_addr);
            await globeContract.connect(walletSigner).depositAll();

            await globeContract.connect(walletSigner).earn();

            strategyBalance = await strategyContract.balanceOf();
            expect(strategyBalance).to.not.be.equals(BigNumber.from("0x0"));
        });
    
        it("Users should earn some money!", async () => {
            let amt;
            [amt,] = await harvester();

            await globeContract.connect(walletSigner).withdrawAll();
            let newAmt = await assetContract.connect(walletSigner).balanceOf(wallet_addr);
            expect(amt).to.be.lt(newAmt);
        });

        it("should be be able change fee distributor", async () =>{
            await strategyContract.connect(governanceSigner).setFeeDistributor(wallet_addr);
            const feeDistributor = await strategyContract.feeDistributor();
            expect(feeDistributor).to.be.equals(wallet_addr);
        });

        it("should be be able change keep amount for fees", async () =>{
            await strategyContract.connect(timelockSigner).setKeep(10);
            keep = await strategyContract.keep();
            expect(keep).to.be.equals(10);
        });

        it("should take no commission when fees not set", async () =>{
            // Set PerformanceTreasuryFee
            await strategyContract.connect(timelockSigner).setPerformanceTreasuryFee(0);
            // Set KeepPNG
            // let keep = await strategyContract.keep();
            // console.log("\tStrategy keep before: ",keep.toString());
            await strategyContract.connect(timelockSigner).setKeep(0);
            // keep = await strategyContract.keep();
            // console.log("\tStrategy keep after: ",keep.toString());

            let snobContract = await ethers.getContractAt("ERC20",snowball_addr,walletSigner);


            const globeBefore = await globeContract.balance();
            const treasuryBefore = await assetContract.connect(walletSigner).balanceOf(treasury_addr);
            const snobBefore = await snobContract.balanceOf(treasury_addr);
            
            await harvester();

            const globeAfter = await globeContract.balance();
            const treasuryAfter = await assetContract.connect(walletSigner).balanceOf(treasury_addr);
            const snobAfter = await snobContract.balanceOf(treasury_addr);
            const earnt = globeAfter.sub(globeBefore);
            const earntTTreasury = treasuryAfter.sub(treasuryBefore);
            const snobAccrued = snobAfter.sub(snobBefore);
            console.log("\t💸Snowglobe profit after harvest: ", earnt.toString());
            // console.log("\t💸Treasury profit after harvest: ", earntTTreasury.toString());
            // console.log("\t💸Snowball token accrued : " + snobAccrued.toString());
            expect(snobAccrued).to.be.lt(BigNumber.from(1));
            expect(earntTTreasury).to.be.lt(BigNumber.from(1));
        });

        it("should take some commission when fees are set", async () =>{
            // Set PerformanceTreasuryFee
            await strategyContract.connect(timelockSigner).setPerformanceTreasuryFee(0);
            // Set KeepPNG
            // let keep = await strategyContract.keep();
            //console.log("\tStrategy keep before: ",keep.toString());
            await strategyContract.connect(timelockSigner).setKeep(1000);
            // keep = await strategyContract.keep();
            //console.log("\tStrategy keep after: ",keep.toString());

            let snobContract = new ethers.Contract(snowball_addr, erc20_ABI, walletSigner);

            const globeBefore = await globeContract.balance();
            const treasuryBefore = await assetContract.connect(walletSigner).balanceOf(treasury_addr);
            const snobBefore = await snobContract.balanceOf(treasury_addr);
            console.log("snobBefore: ",snobBefore.toString());

            await harvester();
            
            const globeAfter = await globeContract.balance();
            // const treasuryAfter = await assetContract.connect(walletSigner).balanceOf(treasury_addr);
            const snobAfter = await snobContract.balanceOf(treasury_addr);
            console.log("snobAfter: ",snobAfter.toString());
            const earnt = globeAfter.sub(globeBefore);
            // const earntTTreasury = treasuryAfter.sub(treasuryBefore);
            const snobAccrued = snobAfter.sub(snobBefore);
            console.log("\t💸Snowglobe profit after harvest: ", earnt.toString());
            // console.log("\t💸Treasury profit after harvest: ", earntTTreasury.toString());
            console.log("\t💸Snowball token accrued : " + snobAccrued);
            expect(snobAccrued).to.be.gt(BigNumber.from(1));
            // expect(earntTTreasury).to.be.gt(BigNumber.from(1));
        });
    });
};
