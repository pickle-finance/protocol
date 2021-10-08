/* eslint-disable no-undef */
const { ethers, network } = require("hardhat");
const chai = require("chai");
const { BigNumber } = require("@ethersproject/bignumber");
const {increaseTime, overwriteTokenAmount, increaseBlock, toGwei, fromWei} = require("./utils/helpers");
const { expect } = chai;
const {setupSigners,snowballAddr, treasuryAddr} = require("./utils/static");


const doLPStrategyTest = (name,assetAddr,snowglobeAddr,strategyAddr,globeABI,stratABI, txnAmt) => {

    const walletAddr = process.env.WALLET_ADDR;
    let assetContract,controllerContract;
    let governanceSigner, strategistSigner, controllerSigner, timelockSigner;
    let globeContract, strategyContract;
    let strategyBalance, slot;

    describe("LP Strategy tests for: "+name, async () => {

        before( async () => {
            const strategyName = `Strategy${name}Lp`;
            const snowglobeName = `SnowGlobe${name}`;

            await network.provider.send('hardhat_impersonateAccount', [walletAddr]);
            walletSigner = ethers.provider.getSigner(walletAddr);
            [timelockSigner,strategistSigner,controllerSigner,governanceSigner] = await setupSigners();
            slot = 1;
            await overwriteTokenAmount(assetAddr,walletAddr,txnAmt,slot);
            assetContract = await ethers.getContractAt("ERC20",assetAddr,walletSigner);
            controllerContract = await ethers.getContractAt("ControllerV4", await controllerSigner.getAddress(), governanceSigner);

            if (snowglobeAddr == "") {
              const globeFactory = await ethers.getContractFactory(snowglobeName);
              globeContract = await globeFactory.deploy(assetAddr, governanceSigner._address, timelockSigner._address, controllerSigner._address);
              await controllerContract.setGlobe(assetAddr, globeContract.address);
            }
            else {
              globeContract = new ethers.Contract(snowglobeAddr, globeABI, governanceSigner);
            }
            
            //If strategy address not supplied then we should deploy and setup a new strategy
            if (strategyAddr == ""){
                const stratFactory = await ethers.getContractFactory(strategyName);
                strategyAddr = await controllerContract.strategies(assetAddr);

                // Now we can deploy the new strategy
                strategyContract = await stratFactory.deploy(governanceSigner._address, strategistSigner._address,controllerSigner._address,timelockSigner._address);
                strategyAddr = strategyContract.address;
                console.log("\tDeployed strategy address is: " + strategyAddr);
                await controllerContract.connect(timelockSigner).approveStrategy(assetAddr,strategyAddr);
                await controllerContract.connect(timelockSigner).setStrategy(assetAddr,strategyAddr);
            } else {
                strategyContract = new ethers.Contract(strategyAddr, stratABI, governanceSigner); //This is not an ABI!
            }
            await strategyContract.connect(governanceSigner).whitelistHarvester(walletAddr);
        });
    
        it("user wallet contains asset balance", async () =>{
            let BNBal = await assetContract.balanceOf(walletAddr);
            const BN = ethers.BigNumber.from(txnAmt)._hex.toString();
            expect(BNBal).to.be.equals(BN);
        });
    
        it("Globe initialized with zero balance for user", async () =>{
            let BNBal = await globeContract.balanceOf(walletSigner._address);
            expect(BNBal).to.be.equals(BigNumber.from("0x0"));
        });
    
        it("Should be able to be configured correctly", async () => {
            expect(await controllerContract.globes(assetAddr)).to.be.equals(snowglobeAddr);
            expect(await controllerContract.strategies(assetAddr)).to.be.equals(strategyAddr);
        });
    
        it("Should be able to deposit/withdraw money into globe", async () => {
            await assetContract.approve(snowglobeAddr,"2500000000000000000000000000");
            let balBefore = await assetContract.connect(walletSigner).balanceOf(snowglobeAddr);
            await globeContract.connect(walletSigner).depositAll();
            
            let userBal = await assetContract.connect(walletSigner).balanceOf(walletAddr);
            expect(userBal).to.be.equals(BigNumber.from("0x0"));
    
            let balAfter = await assetContract.connect(walletSigner).balanceOf(snowglobeAddr);
            expect(balBefore).to.be.lt(balAfter);
    
            await globeContract.connect(walletSigner).withdrawAll();
            
            userBal = await assetContract.connect(walletSigner).balanceOf(walletAddr);
            expect(userBal).to.be.gt(BigNumber.from("0x0"));
        });
    
        it("Harvests should make some money!", async () => {
            await overwriteTokenAmount(assetAddr,walletAddr,txnAmt,slot);
            let amt = await assetContract.connect(walletSigner).balanceOf(walletAddr);

            await assetContract.connect(walletSigner).approve(snowglobeAddr,amt);
            let balBefore = await assetContract.connect(walletSigner).balanceOf(snowglobeAddr);
            await globeContract.connect(walletSigner).depositAll();
            
            let userBal = await assetContract.connect(walletSigner).balanceOf(walletAddr);
            expect(userBal).to.be.equals(BigNumber.from("0x0"));
    
            let balAfter = await assetContract.connect(walletSigner).balanceOf(snowglobeAddr);
            expect(balBefore).to.be.lt(balAfter);
            await globeContract.connect(walletSigner).earn();
            await increaseTime(60 * 60 * 24);
            await increaseBlock(60 * 60);

            let harvestable = await strategyContract.getHarvestable();
            console.log("harvestable, pre harvest: ",harvestable.toString());
            let initialBalance = await strategyContract.balanceOf();
    
            await strategyContract.connect(walletSigner).harvest();
            await increaseBlock(1);
            harvestable = await strategyContract.getHarvestable();
            console.log("harvestable, post harvest: ",harvestable.toString());

            let newBalance = await strategyContract.balanceOf();
            expect(newBalance).to.be.gt(initialBalance);
        });

        it("Strategy loaded with initial balance", async () =>{
            strategyBalance = await strategyContract.balanceOf();
            expect(strategyBalance).to.not.be.equals(BigNumber.from("0x0"));
        });
    
        it("Users should earn some money!", async () => {
            await overwriteTokenAmount(assetAddr,walletAddr,txnAmt,slot);
            let amt = await assetContract.connect(walletSigner).balanceOf(walletAddr);

            await assetContract.connect(walletSigner).approve(snowglobeAddr,amt);
            let balBefore = await assetContract.connect(walletSigner).balanceOf(snowglobeAddr);
            await globeContract.connect(walletSigner).depositAll();
            
            let userBal = await assetContract.connect(walletSigner).balanceOf(walletAddr);
            expect(userBal).to.be.equals(BigNumber.from("0x0"));
    
            let balAfter = await assetContract.connect(walletSigner).balanceOf(snowglobeAddr);
            expect(balBefore).to.be.lt(balAfter);

            await globeContract.connect(walletSigner).earn();
            await increaseTime(60 * 60 * 24);
            await increaseBlock(60 * 60);

            let harvestable = await strategyContract.getHarvestable();
            console.log("harvestable, pre harvest: ",harvestable.toString());

            await strategyContract.connect(walletSigner).harvest();
            await increaseBlock(1);
            harvestable = await strategyContract.getHarvestable();
            console.log("harvestable, post harvest: ",harvestable.toString());

            await globeContract.connect(walletSigner).withdrawAll();
            let newAmt = await assetContract.connect(walletSigner).balanceOf(walletAddr);

            expect(amt).to.be.lt(newAmt);
            //let totalDeposit = amt.mul(2);
            //let difference = newAmt.sub(totalDeposit);
            //let apr = difference.mul(5200).div(2).div(totalDeposit);
            //console.log("\tBasic APR for depositing into strategy "+name+" is about "+apr+"%");
        });

        it("should be be able change fee distributor", async () =>{
            await strategyContract.connect(governanceSigner).setFeeDistributor(walletAddr);
            const feeDistributor = await strategyContract.feeDistributor();
            expect(feeDistributor).to.be.equals(walletAddr);
        });

        it("should be be able change keep amount for fees", async () =>{
            await strategyContract.connect(timelockSigner).setKeep(10);
            keep = await strategyContract.keep();
            expect(keep).to.be.equals(10);
        });

        it("should take no commission when fees not set", async () =>{
            await overwriteTokenAmount(assetAddr,walletAddr,txnAmt,slot);
            let amt = await assetContract.connect(walletSigner).balanceOf(walletAddr);
            console.log("amt: ",amt.toString());

            await assetContract.connect(walletSigner).approve(snowglobeAddr,amt);
            let balBefore = await assetContract.connect(walletSigner).balanceOf(snowglobeAddr);
            await globeContract.connect(walletSigner).depositAll();
            
            let userBal = await assetContract.connect(walletSigner).balanceOf(walletAddr);
            expect(userBal).to.be.equals(BigNumber.from("0x0"));
    
            let balAfter = await assetContract.connect(walletSigner).balanceOf(snowglobeAddr);
            expect(balBefore).to.be.lt(balAfter);
            
            await globeContract.connect(walletSigner).earn();
            await increaseTime(60 * 60 * 24);
            await increaseBlock(60 * 60);

            // Set PerformanceTreasuryFee
            await strategyContract.connect(timelockSigner).setPerformanceTreasuryFee(0);
            // Set KeepPNG
            let keep = await strategyContract.keep();
            console.log("strategy keep before: ",keep.toString());
            await strategyContract.connect(timelockSigner).setKeep(0);
            keep = await strategyContract.keep();
            console.log("strategy keep after: ",keep.toString());

            let snobContract = await ethers.getContractAt("ERC20",snowballAddr,walletSigner);


            const globeBefore = await globeContract.balance();
            const treasuryBefore = await assetContract.connect(walletSigner).balanceOf(treasuryAddr);
            const snobBefore = await snobContract.balanceOf(treasuryAddr);
            //console.log("\tSnowglobe balance before harvest: ", globeBefore.toString());
            //console.log("\tTreasury balance before harvest: ", treasuryBefore.toString());
            //console.log("\tQI harvest is: " + harvestQI+", AVAX harvest is: "+ harvestAVAX);

            let harvestable = await strategyContract.getHarvestable();
            console.log("harvestable, pre harvest: ",harvestable.toString());

            await strategyContract.connect(walletSigner).harvest();
            await increaseBlock(1);
            harvestable = await strategyContract.getHarvestable();
            console.log("harvestable, post harvest: ",harvestable.toString());

            const globeAfter = await globeContract.balance();
            const treasuryAfter = await assetContract.connect(walletSigner).balanceOf(treasuryAddr);
            const snobAfter = await snobContract.balanceOf(treasuryAddr);
            //console.log("\tSnowglobe balance after harvest: ", globeAfter.toString());
            //console.log("\tTreasury balance after harvest: ", treasuryAfter.toString());
            //console.log("\tQI harvest is: " + harvestQI+", AVAX harvest is: "+ harvestAVAX);
            const earnt = globeAfter.sub(globeBefore);
            const earntTTreasury = treasuryAfter.sub(treasuryBefore);
            const snobAccrued = snobAfter.sub(snobBefore);
            console.log("\t💸Snowglobe profit after harvest: ", earnt.toString());
            console.log("\t💸Treasury profit after harvest: ", earntTTreasury.toString());
            console.log("\t💸Snowball token accrued : " + snobAccrued.toString());
            expect(snobAccrued).to.be.lt(BigNumber.from(1));
            expect(earntTTreasury).to.be.lt(BigNumber.from(1));
        });

        it("should take some commission when fees are set", async () =>{
            await overwriteTokenAmount(assetAddr,walletAddr,txnAmt,slot);
            let amt = await assetContract.connect(walletSigner).balanceOf(walletAddr);

            await assetContract.connect(walletSigner).approve(snowglobeAddr,amt);
            await globeContract.connect(walletSigner).deposit(amt);
            await globeContract.connect(walletSigner).earn();
            await increaseTime(60 * 60 * 24);
            await increaseBlock(60 * 60);

            // Set PerformanceTreasuryFee
            await strategyContract.connect(timelockSigner).setPerformanceTreasuryFee(0);
            // Set KeepPNG
            let keep = await strategyContract.keep();
            console.log("strategy keep before: ",keep.toString());
            await strategyContract.connect(timelockSigner).setKeep(1000);
            keep = await strategyContract.keep();
            console.log("strategy keep after: ",keep.toString());

            let snobContract = await ethers.getContractAt("ERC20",snowballAddr,walletSigner);

            const globeBefore = await globeContract.balance();
            const treasuryBefore = await assetContract.connect(walletSigner).balanceOf(treasuryAddr);
            const snobBefore = await snobContract.balanceOf(treasuryAddr);
            // console.log("\tSnowglobe balance before harvest: ", globeBefore.toString());
            // console.log("\tTreasury balance before harvest: ", treasuryBefore.toString());
            // console.log("\tQI harvest is: " + harvestQI+", AVAX harvest is: "+ harvestAVAX);

             let harvestable = await strategyContract.getHarvestable();
            console.log("harvestable, pre harvest: ",harvestable.toString());

            await strategyContract.connect(walletSigner).harvest();
            await increaseBlock(1);
            harvestable = await strategyContract.getHarvestable();
            console.log("harvestable, post harvest: ",harvestable.toString());

            const globeAfter = await globeContract.balance();
            const treasuryAfter = await assetContract.connect(walletSigner).balanceOf(treasuryAddr);
            const snobAfter = await snobContract.balanceOf(treasuryAddr);
            // console.log("\tSnowglobe balance after harvest: ", globeAfter.toString());
            // console.log("\tTreasury balance after harvest: ", treasuryAfter.toString());
            // console.log("\tQI harvest is: " + harvestQI+", AVAX harvest is: "+ harvestAVAX);
            const earnt = globeAfter.sub(globeBefore);
            const earntTTreasury = treasuryAfter.sub(treasuryBefore);
            const snobAccrued = snobAfter.sub(snobBefore);
            console.log("\t💸Snowglobe profit after harvest: ", earnt.toString());
            console.log("\t💸Treasury profit after harvest: ", earntTTreasury.toString());
            console.log("\t💸Snowball token accrued : " + snobAccrued);
            expect(snobAccrued).to.be.gt(BigNumber.from(1));
            // expect(earntTTreasury).to.be.gt(BigNumber.from(1));
        });
    });
};

module.exports = {doLPStrategyTest};