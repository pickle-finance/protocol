/* eslint-disable no-undef */
const { ethers, network } = require("hardhat");
import { BigNumber } from "@ethersproject/bignumber";
import chaiModule from "chai";
import chaiAsPromised = require("chai-as-promised");
import { expect } from "chai";
import { 
   Contract, 
   Signer 
} from "ethers";
import { setupMockStrategy } from "./mocks/Strategy"; 
import { setupMockSnowGlobe } from "./mocks/SnowGlobe"; 
import { log } from "./utils/log";
import  {
   userWalletAssetBalance, globeHasBalance, controllerGlobeConfigure, 
   controllerStrategyConfigure, harvestsMakeMoney, globeDepositWithdraw,
   strategyLoadedWithBalance, usersEarnMoney, takeNoFees,
   changeFeeDistributor, changeKeepAmountForFees, takeSomeFees,
} from "./utils/its";
import { 
   increaseTime, overwriteTokenAmount, returnController,
   returnSigner, snowglobeEarn, setStrategy, increaseBlock,
   whitelistHarvester
} from "./utils/helpers";
import { 
   setupSigners, snowball_addr, 
   treasury_addr 
} from "./utils/static";


export function doLPStrategyTest (
    name: string, 
    snowglobe_addr: string,
    slot: number,
    controller: string,
    lp_suffix: boolean = true
) {

    const wallet_addr = process.env.WALLET_ADDR === undefined ? '' : process.env['WALLET_ADDR'];

    let assetContract:      Contract;
    let Controller:         Contract;
    let SnowGlobe:          Contract;
    let Strategy:           Contract;

    let governanceSigner:   Signer;
    let strategistSigner:   Signer;
    let walletSigner:       Signer;
    let controllerSigner:   Signer;
    let timelockSigner:     Signer;

    let strategyBalance:    string; 
    let controller_addr:    string;
    let strategy_addr:      string;
    let asset_addr:         string;
    let governance_addr:    string;
    let strategist_addr:    string;
    let timelock_addr:      string;
    let snapshotId:         string;

    let txnAmt: string = "25000000000000000000000";

    describe("LP Strategy tests for: "+name, async () => {

        //These reset the state after each test is executed 
        beforeEach(async () => {
            snapshotId = await ethers.provider.send('evm_snapshot');
        });
  
        afterEach(async () => {
            await ethers.provider.send('evm_revert', [snapshotId]);
        });

        before( async () => {
            const strategyName = lp_suffix ? `Strategy${name}Lp` : `Strategy${name}`;
            const snowglobeName = `SnowGlobe${name}`;

            controller_addr = returnController(controller); 

            await network.provider.send('hardhat_impersonateAccount', [wallet_addr]);
            walletSigner = ethers.provider.getSigner(wallet_addr);
            [timelockSigner,strategistSigner,governanceSigner] = await setupSigners();

            Controller = await ethers.getContractAt("ControllerV4", controller_addr, governanceSigner);

            timelock_addr   = await timelockSigner.getAddress();
            governance_addr = await governanceSigner.getAddress()
            strategist_addr = await strategistSigner.getAddress()
            
            Strategy = await setupMockStrategy(
               strategyName, 
               "", 
               false,
               Controller,
               walletSigner, 
               timelockSigner, 
               governanceSigner,
               strategistSigner
            );
            console.log(i++)

            asset_addr = await Strategy.want();
            assetContract = await ethers.getContractAt("ERC20", asset_addr, walletSigner);
            timelock_addr = await Strategy.timelock();
            timelockSigner = await returnSigner(timelock_addr);

            SnowGlobe = await setupMockSnowGlobe(
               snowglobeName, 
               snowglobe_addr, 
               asset_addr,
               Controller, 
               timelockSigner, 
               governanceSigner
            ); 
            console.log(i++)
            
            snowglobe_addr = SnowGlobe.address;
            strategy_addr = Strategy.address;

            await setStrategy(name, Controller, timelockSigner, asset_addr, strategy_addr); 
            await whitelistHarvester(name, Strategy, governanceSigner, wallet_addr);
            await snowglobeEarn(name, SnowGlobe);
            
            await overwriteTokenAmount(asset_addr,wallet_addr,txnAmt,slot);
        });

        const harvester = async () => {
            await overwriteTokenAmount(asset_addr,wallet_addr,txnAmt,slot);
            let amt = await assetContract.connect(walletSigner).balanceOf(wallet_addr);

            await assetContract.connect(walletSigner).approve(snowglobe_addr,amt);
            let balBefore = await assetContract.connect(walletSigner).balanceOf(snowglobe_addr);
            await SnowGlobe.connect(walletSigner).depositAll();
            
            let userBal = await assetContract.connect(walletSigner).balanceOf(wallet_addr);
            expect(userBal).to.be.equals(BigNumber.from("0x0"));
    
            let balAfter = await assetContract.connect(walletSigner).balanceOf(snowglobe_addr);
            expect(balBefore).to.be.lt(balAfter);
            await SnowGlobe.connect(walletSigner).earn();
            await increaseTime(60 * 60 * 24 * 30);
            await increaseBlock(60 * 60);

            let harvestable = await Strategy.getHarvestable();
            log(`\tHarvestable, pre harvest: ${harvestable.toString()}`);
            let initialBalance = await Strategy.balanceOf();
            await Strategy.connect(walletSigner).harvest();
            await increaseBlock(1);
            harvestable = await Strategy.getHarvestable();
            log(`\tHarvestable, post harvest: ${harvestable.toString()}`);

            return [amt, initialBalance];
        };

        it("user wallet contains asset balance", async function () {
            await userWalletAssetBalance(txnAmt, assetContract, walletSigner);
        });

        it("Globe initialized with zero balance for user", async function () {
            await globeHasBalance(SnowGlobe, walletSigner);
        });

        it("Controller globe to be configured correctly", async function () {
           await controllerGlobeConfigure(Controller, asset_addr, snowglobe_addr); 
        });

        it("Controller strategy to be configured correctly", async () => {
           await controllerStrategyConfigure(Controller, asset_addr, strategy_addr)
        });

        it("Should be able to deposit/withdraw money into globe", async function () {
            await globeDepositWithdraw(assetContract, SnowGlobe, walletSigner);
        });

        it("Harvests should make some money!", async function () {
            await harvestsMakeMoney(Strategy, harvester);
        });

        it("Strategy loaded with initial balance", async function () {
           await strategyLoadedWithBalance(assetContract, SnowGlobe, Strategy, walletSigner);
        });

        it("Users should earn some money!", async function () {
            await usersEarnMoney(assetContract, SnowGlobe, Strategy, walletSigner, txnAmt, slot)
        });

        it("should be be able change fee distributor", async () =>{
            await changeFeeDistributor(Strategy, governanceSigner, wallet_addr);
        });

        it("should be be able change keep amount for fees", async () =>{
            await changeKeepAmountForFees(Strategy, timelockSigner);
        });

        // Issue raised at: https://github.com/Snowball-Finance/protocol/issues/76
        it("should take no commission when fees not set", async function () {
            await takeNoFees(assetContract, SnowGlobe, Strategy, walletSigner, timelockSigner, txnAmt, slot);
        }); 

        it("should take some commission when fees are set", async function () {
           await takeSomeFees(harvester, assetContract, SnowGlobe, Strategy, walletSigner, timelockSigner, txnAmt, slot);
        });

    });
};
