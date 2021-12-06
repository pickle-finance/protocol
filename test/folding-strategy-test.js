/* eslint-disable no-undef */
const { ethers, network } = require("hardhat");
const chai = require("chai");
const { BigNumber } = require("@ethersproject/bignumber");
const { increaseTime, overwriteTokenAmount, increaseBlock, returnSigner, fastForwardAWeek } = require("./utils/helpers");
const { expect } = chai;
const { setupSigners, snowballAddr, treasuryAddr} = require("./utils/static");

const doFoldingStrategyTest = (
    name,
    assetAddr,
    snowglobeAddr,
    strategyAddr,
    globeABI,
    stratABI,
    txnAmt = "250000000000000000000000",
    slot = "0",
    fold = true,
    controller = "bankerJoe",) => {

    const walletAddr = process.env.WALLET_ADDR;
    let assetContract, controllerContract;
    let governanceSigner, strategistSigner, controllerSigner, timelockSigner;
    let globeContract, strategyContract;
    let strategyBalance, controllerAddr;

    describe("Folding Strategy tests for: " + name, async () => {

        before(async () => {
            const strategyName = `Strategy${name}`;
            const snowglobeName = `SnowGlobe${name}`;

            [timelockSigner, strategistSigner, governanceSigner] = await setupSigners();

            //Add a new case here when including a new family of folding strategies
            switch (controller) {
                case "main": controllerAddr = "0xf7B8D9f8a82a7a6dd448398aFC5c77744Bd6cb85";break;
                case "backup": controllerAddr = "0xACc69DEeF119AB5bBf14e6Aaf0536eAFB3D6e046"; break;
                case "aave": controllerAddr = "0x425A863762BBf24A986d8EaE2A367cb514591C6F"; break;
                case "bankerJoe": controllerAddr = "0xFb7102506B4815a24e3cE3eAA6B834BE7a5f2807"; break;
                default : break;
            }

            controllerSigner = await returnSigner(controllerAddr);
            walletSigner = await returnSigner(walletAddr);

            await overwriteTokenAmount(assetAddr, walletAddr, txnAmt, slot);

            assetContract = await ethers.getContractAt("ERC20", assetAddr, walletSigner);
            controllerContract = await ethers.getContractAt("ControllerV4", controllerAddr, governanceSigner);

            //If snowglobe address not supplied then we should deploy and setup a new snowglobe
            if (snowglobeAddr == "") {
                const globeFactory = await ethers.getContractFactory(snowglobeName);
                globeContract = await globeFactory.deploy(assetAddr, governanceSigner._address, timelockSigner._address, controllerAddr);
                await controllerContract.setGlobe(assetAddr, globeContract.address);
                snowglobeAddr = globeContract.address;
            }
            else {
                globeContract = new ethers.Contract(snowglobeAddr, globeABI, governanceSigner);
            }


            //If strategy address not supplied then we should deploy and setup a new strategy
            if (strategyAddr == "") {
                const stratFactory = await ethers.getContractFactory(strategyName);
                strategyAddr = await controllerContract.strategies(assetAddr);

                if (fold == true) {
                    // Before we can setup new strategy we must deleverage from old one
                    strategyContract = await stratFactory.attach(strategyAddr);
                    console.log("\t" + name + " is being deleveraged before new contract is deployed");
                    await strategyContract.connect(governanceSigner).deleverageToMin();
                }

                // Now we can deploy the new strategy
                strategyContract = await stratFactory.deploy(governanceSigner._address, strategistSigner._address, controllerAddr, timelockSigner._address);
                strategyAddr = strategyContract.address;
                // console.log("\tDeployed strategy address is: " + strategyAddr);
                await controllerContract.connect(timelockSigner).approveStrategy(assetAddr, strategyAddr);
                await controllerContract.connect(timelockSigner).setStrategy(assetAddr, strategyAddr);
            } else {            

                strategyContract = new ethers.Contract(strategyAddr, stratABI, governanceSigner);
                let timelockAddr = await strategyContract.timelock();
                timelockSigner = await returnSigner(timelockAddr);

            }
            await strategyContract.connect(governanceSigner).whitelistHarvester(walletAddr);
        });

        it("user wallet contains asset balance", async () => {
            let BNBal = await assetContract.balanceOf(await walletSigner.getAddress());
            const BN = ethers.BigNumber.from(txnAmt)._hex.toString();
            expect(BNBal).to.be.equals(BN);
        });

        it("Globe initialized with zero balance for user", async () => {
            let BNBal = await globeContract.balanceOf(walletSigner._address);
            expect(BNBal).to.be.equals(BigNumber.from("0x0"));
        });

        it("Should be able to be configured correctly", async () => {
            expect(await controllerContract.globes(assetAddr)).to.contains(snowglobeAddr);
            //expect(await controllerContract.strategies(assetAddr)).to.be.equals(strategyAddr);
        });

        it("Should be able to deposit/withdraw money into globe", async () => {
            await assetContract.approve(snowglobeAddr, "2500000000000000000000000000");
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
            await overwriteTokenAmount(assetAddr, walletAddr, txnAmt, slot);
            let amt = await assetContract.connect(walletSigner).balanceOf(walletAddr);

            await assetContract.connect(walletSigner).approve(snowglobeAddr, amt);
            await globeContract.connect(walletSigner).deposit(amt);
            await globeContract.connect(walletSigner).earn();

            await fastForwardAWeek();

            let initialBalance = await strategyContract.balanceOf();

            await strategyContract.connect(walletSigner).harvest();
            await increaseBlock(2);

            let newBalance = await strategyContract.balanceOf();
            expect(newBalance).to.be.gt(initialBalance);
        });

        it("Strategy loaded with initial balance", async () => {
            strategyBalance = await strategyContract.balanceOf();
            expect(strategyBalance).to.not.be.equals(BigNumber.from("0x0"));
        });

        it("Users should earn some money!", async () => {
            await overwriteTokenAmount(assetAddr, walletAddr, txnAmt, slot);
            let amt = await assetContract.connect(walletSigner).balanceOf(walletAddr);

            await assetContract.connect(walletSigner).approve(snowglobeAddr, amt);
            await globeContract.connect(walletSigner).deposit(amt);
            await globeContract.connect(walletSigner).earn();

            await fastForwardAWeek();

            await strategyContract.connect(walletSigner).harvest();
            await increaseBlock(1);

            await globeContract.connect(walletSigner).withdrawAll();
            let newAmt = await assetContract.connect(walletSigner).balanceOf(walletAddr);

            expect(amt).to.be.lt(newAmt);
        });

        // Issue raised at: https://github.com/Snowball-Finance/protocol/issues/76
        it("should take no commission when fees not set", async () =>{
            await overwriteTokenAmount(assetAddr,walletAddr,txnAmt,slot);
            let amt = await assetContract.connect(walletSigner).balanceOf(walletAddr);

            await assetContract.connect(walletSigner).approve(snowglobeAddr,amt);
            await globeContract.connect(walletSigner).deposit(amt);
            await globeContract.connect(walletSigner).earn();

            await fastForwardAWeek();

            // Set PerformanceTreasuryFee
            await strategyContract.connect(timelockSigner).setPerformanceTreasuryFee(0);

            // Set KeepPNG
            await strategyContract.connect(timelockSigner).setKeep(0);
            let snobContract = await ethers.getContractAt("ERC20",snowballAddr,walletSigner);

            const globeBefore = await globeContract.balance();
            const treasuryBefore = await assetContract.connect(walletSigner).balanceOf(treasuryAddr);
            const snobBefore = await snobContract.balanceOf(treasuryAddr);

            await strategyContract.connect(walletSigner).harvest();
            await increaseBlock(1);
            const globeAfter = await globeContract.balance();
            const treasuryAfter = await assetContract.connect(walletSigner).balanceOf(treasuryAddr);
            const snobAfter = await snobContract.balanceOf(treasuryAddr);
            const earnt = globeAfter.sub(globeBefore);
            const earntTTreasury = treasuryAfter.sub(treasuryBefore);
            const snobAccrued = snobAfter.sub(snobBefore);
            // console.log("\t💸Snowglobe profit after harvest: ", earnt.toString());
            // console.log("\t💸Treasury profit after harvest: ", earntTTreasury.toString());
            // console.log("\t💸Snowball token accrued : " + snobAccrued.toString());
            expect(snobAccrued).to.be.lt(BigNumber.from(1));
            expect(earntTTreasury).to.be.lt(BigNumber.from(1));
        }); 

        it("should take some commission when fees are set", async () => {
            await overwriteTokenAmount(assetAddr, walletAddr, txnAmt, slot);
            let amt = await assetContract.connect(walletSigner).balanceOf(walletAddr);

            await assetContract.connect(walletSigner).approve(snowglobeAddr, amt);
            await globeContract.connect(walletSigner).deposit(amt);
            await globeContract.connect(walletSigner).earn();
            await fastForwardAWeek();

            // Set PerformanceTreasuryFee
            await strategyContract.connect(timelockSigner).setPerformanceTreasuryFee(0);
            // Set KeepPNG
            await strategyContract.connect(timelockSigner).setKeep(1000);

            let snobContract = await ethers.getContractAt("ERC20", snowballAddr, walletSigner);

            const globeBefore = await globeContract.balance();
            const treasuryBefore = await assetContract.connect(walletSigner).balanceOf(treasuryAddr);
            const snobBefore = await snobContract.balanceOf(treasuryAddr);

            await strategyContract.connect(walletSigner).harvest();
            await increaseBlock(1);

            const globeAfter = await globeContract.balance();
            const treasuryAfter = await assetContract.connect(walletSigner).balanceOf(treasuryAddr);
            const snobAfter = await snobContract.balanceOf(treasuryAddr);
            const earnt = globeAfter.sub(globeBefore);
            const earntTTreasury = treasuryAfter.sub(treasuryBefore);
            const snobAccrued = snobAfter.sub(snobBefore);
            // console.log("\t💸Snowglobe profit after harvest: ", earnt.toString());
            // console.log("\t💸Treasury profit after harvest: ", earntTTreasury.toString());
            // console.log("\t💸Snowball token accrued : " + snobAccrued);
            expect(snobAccrued).to.be.gt(BigNumber.from(1));
            // expect(earntTTreasury).to.be.gt(BigNumber.from(1));
        });

    });

};

module.exports = { doFoldingStrategyTest };