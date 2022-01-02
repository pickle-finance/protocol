/* eslint-disable no-undef */
const { ethers } = require("hardhat");
import { BigNumber } from "@ethersproject/bignumber";
import chaiModule from "chai";
import { expect } from "chai";
import { 
   Contract, 
   ContractFactory,
   Signer 
} from "ethers";
import { 
   setupSigners, 
   snowballAddr, 
   treasuryAddr 
} from "../utils/static";
import { 
   increaseTime, 
   overwriteTokenAmount, 
   increaseBlock, 
   returnSigner, 
   returnController, 
   fastForwardAWeek,
} from "../utils/helpers";

/************/
export function doFoldingStrategyTest(
    name: string,
    assetAddr: string,
    snowglobeAddr: string,
    strategyAddr: string,
    globeABI: Object,
    stratABI: Object,
    txnAmt: string = "250000000000000000000000",
    slot: number = 0,
    fold: boolean = true,
    controller: string = "main") {

    const walletAddr = process.env.WALLET_ADDR === undefined ? '' : process.env['WALLET_ADDR'];
    let assetContract:        Contract;
    let controllerContract:   Contract;
    let globeContract:        Contract;
    let strategyContract:     Contract;

    let governanceSigner:     Signer;
    let strategistSigner:     Signer;
    let walletSigner:         Signer;
    let controllerSigner:     Signer;
    let timelockSigner:       Signer;

    let strategyBalance:      string; 
    let controllerAddr:       string;
    let snapshotId: string;

    describe("Folding Strategy tests for: " + name, async () => {

        beforeEach(async () => {
            snapshotId = await ethers.provider.send('evm_snapshot');
        });
        afterEach(async () => {
            await ethers.provider.send('evm_revert', [snapshotId]);
        });


        before(async () => {
            const strategyName: string  = `Strategy${name}`;
            const snowglobeName: string = `SnowGlobe${name}`;

            [timelockSigner, strategistSigner, governanceSigner] = await setupSigners();

            //Add a new case here when including a new family of folding strategies
            controllerAddr = returnController(controller);
            controllerSigner = await returnSigner(controllerAddr);
            walletSigner = await returnSigner(walletAddr);

            await overwriteTokenAmount(assetAddr, walletAddr, txnAmt, slot);

            assetContract = await ethers.getContractAt("ERC20", assetAddr, walletSigner);
            controllerContract = await ethers.getContractAt("ControllerV4", controllerAddr, governanceSigner);

            //If snowglobe getAddress() not supplied then we should deploy and setup a new snowglobe
            if (snowglobeAddr == "") {
                const globeFactory: ContractFactory = await ethers.getContractFactory(snowglobeName);
                globeContract = await globeFactory.deploy(assetAddr, governanceSigner.getAddress(), timelockSigner.getAddress(), controllerAddr);
                await controllerContract.setGlobe(assetAddr, globeContract.getAddress());
                snowglobeAddr = globeContract.getAddress();
            }
            else {
                globeContract = new ethers.Contract(snowglobeAddr, globeABI, governanceSigner);
            }

            //If strategy getAddress() not supplied then we should deploy and setup a new strategy
            if (strategyAddr == "") {
                const stratFactory: ContractFactory = await ethers.getContractFactory(strategyName);
                strategyAddr = await controllerContract.strategies(assetAddr);

                if (fold == true) {
                    // Before we can setup new strategy we must deleverage from old one
                    strategyContract = await stratFactory.attach(strategyAddr);
                    console.log("\t" + name + " is being deleveraged before new contract is deployed");
                    await strategyContract.connect(governanceSigner).deleverageToMin();
                }

                // Now we can deploy the new strategy
                strategyContract = await stratFactory.deploy(governanceSigner.getAddress(), strategistSigner.getAddress(), controllerAddr, timelockSigner.getAddress());
                strategyAddr = strategyContract.getAddress();
                // console.log("\tDeployed strategy getAddress() is: " + strategyAddr);
                await controllerContract.connect(timelockSigner).approveStrategy(assetAddr, strategyAddr);
                await controllerContract.connect(timelockSigner).setStrategy(assetAddr, strategyAddr);
            } else {            
                strategyContract = new ethers.Contract(strategyAddr, stratABI, governanceSigner);
                let timelockAddr: string = await strategyContract.timelock();
                timelockSigner = await returnSigner(timelockAddr);

            }

            await strategyContract.connect(governanceSigner).whitelistHarvester(walletAddr);
        });

        it("user wallet contains asset balance", async () => {
            let BNBal: string = await assetContract.balanceOf(await walletSigner.getAddress());
            const BN: string = ethers.BigNumber.from(txnAmt)._hex.toString();
            expect(BNBal).to.be.equals(BN);
        });

        it("Globe initialized with zero balance for user", async () => {
            let BNBal: string = await globeContract.balanceOf(walletSigner.getAddress());
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
            //expect(userBal).to.be.gt(BigNumber.from("0x0"));
            expect(userBal).to.be.gt(0);
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

            const globeBefore: BigNumber = await globeContract.balance();
            const treasuryBefore: BigNumber = await assetContract.connect(walletSigner).balanceOf(treasuryAddr);
            const snobBefore: BigNumber = await snobContract.balanceOf(treasuryAddr);

            await strategyContract.connect(walletSigner).harvest();
            await increaseBlock(1);
            const globeAfter: BigNumber = await globeContract.balance();
            const treasuryAfter: BigNumber = await assetContract.connect(walletSigner).balanceOf(treasuryAddr); const snobAfter: BigNumber = await snobContract.balanceOf(treasuryAddr); const earnt: BigNumber = globeAfter.sub(globeBefore);
            const earntTTreasury: BigNumber = treasuryAfter.sub(treasuryBefore);
            const snobAccrued: BigNumber = snobAfter.sub(snobBefore);
            // console.log("\t💸Snowglobe profit after harvest: ", earnt.toString());
            // console.log("\t💸Treasury profit after harvest: ", earntTTreasury.toString());
            // console.log("\t💸Snowball token accrued : " + snobAccrued.toString());
            //expect(snobAccrued).to.be.lt(BigNumber.from(1));
            expect(snobAccrued).to.be.lt(1);
            expect(earntTTreasury).to.be.lt(1);
            //expect(earntTTreasury).to.be.lt(BigNumber.from(1));
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
            //expect(snobAccrued).to.be.gt(BigNumber.from(1));
            //expect(snobAccrued.gt(BigNumber.from(1))).to.be.true;
            expect(snobAccrued).to.be.gt(1);
            // expect(earntTTreasury).to.be.gt(BigNumber.from(1));
        });

    });

};

