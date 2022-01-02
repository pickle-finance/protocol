/* eslint-disable no-undef */
const { ethers, network } = require("hardhat");
const hre = "hardhat";
import { BigNumber } from "@ethersproject/bignumber";
import chai from "chai";
import { expect } from "chai";
import { log } from "./utils/log";
import { setupMockStrategy } from "./mocks/Strategy";
import { setupMockSnowGlobe } from "./mocks/SnowGlobe";
import {
    Contract,
    ContractFactory,
    Signer
} from "ethers";
import {
    setupSigners,
    snowball_addr,
    treasury_addr
} from "./utils/static";
import {
    increaseTime, overwriteTokenAmount, increaseBlock,
    returnSigner, returnController, fastForwardAWeek,
    setStrategy, whitelistHarvester, setKeeper,
    snowglobeEarn, strategyFold, addGauge
} from "./utils/helpers";
import {
    userWalletAssetBalance, globeHasBalance, controllerGlobeConfigure,
    controllerStrategyConfigure, harvestsMakeMoney, globeDepositWithdraw,
    strategyLoadedWithBalance, usersEarnMoney, takeNoFees,
    takeSomeFees,
} from "./utils/its";

import { TestableStrategy } from "./strategy-test-case";

export function doStrategyTest(test_case: TestableStrategy) {

    const wallet_addr = process.env.WALLET_ADDR === undefined ? '' : process.env['WALLET_ADDR'];
    let name = test_case.name;
    let snowglobe_addr = test_case.snowglobeAddress;
    let strategy_addr = test_case.strategyAddress;
    let fold = test_case.fold;
    let slot = test_case.slot;
    let controller = test_case.controller;
    let lp_suffix = test_case.lp_suffix;
    let timelockIsStrategist = test_case.timelockIsStrategist;

    let assetContract: Contract;
    let Controller: Contract;
    let SnowGlobe: Contract;
    let Strategy: Contract;

    let governanceSigner: Signer;
    let strategistSigner: Signer;
    let walletSigner: Signer;
    let controllerSigner: Signer;
    let timelockSigner: Signer;

    let strategyBalance: string;
    let controller_addr: string;
    let asset_addr: string;
    let governance_addr: string;
    let strategist_addr: string;
    let timelock_addr: string;
    let snapshotId: string;

    let txnAmt: string = "25000000000000000000000";

    describe("Folding Strategy tests for: " + name, async () => {

        beforeEach(async () => {
            snapshotId = await ethers.provider.send('evm_snapshot');
        });
        afterEach(async () => {
            await ethers.provider.send('evm_revert', [snapshotId]);
        });


        before(async () => {

            const strategyName = lp_suffix ? `Strategy${name}Lp` : `Strategy${name}`;
            const snowglobeName = `SnowGlobe${name}`;

            await network.provider.send('hardhat_impersonateAccount', [wallet_addr]);
            log(`impersonating account: ${wallet_addr}`);
            walletSigner = await returnSigner(wallet_addr);
            [timelockSigner, strategistSigner, governanceSigner] = await setupSigners(timelockIsStrategist);

            //Add a new case here when including a new family of folding strategies
            controller_addr = returnController(controller);
            Controller = await ethers.getContractAt("ControllerV4", controller_addr, governanceSigner);
            log(`using controller: ${controller_addr}`);

            timelock_addr = await timelockSigner.getAddress();
            governance_addr = await governanceSigner.getAddress()
            strategist_addr = await strategistSigner.getAddress()

            /** Strategy Mock **/
            Strategy = await setupMockStrategy(
                strategyName,
                strategy_addr,
                fold,
                Controller,
                walletSigner,
                timelockSigner,
                governanceSigner,
                strategistSigner
            );

            asset_addr = await Strategy.want();
            assetContract = await ethers.getContractAt("ERC20", asset_addr, walletSigner);
            // ensure timelocker is same as used in Strategy
            timelock_addr = await Strategy.timelock();
            timelockSigner = await returnSigner(timelock_addr);

            /** SnowGlobe Mock **/
            SnowGlobe = await setupMockSnowGlobe(
                snowglobeName,
                snowglobe_addr,
                asset_addr,
                Controller,
                timelockSigner,
                governanceSigner
            );

            // ensure addresses
            strategy_addr = Strategy.address;
            snowglobe_addr = SnowGlobe.address;

            /** Access **/
            await setStrategy(name, Controller, timelockSigner, asset_addr, strategy_addr);
            await whitelistHarvester(name, Strategy, governanceSigner, wallet_addr);
            if (test_case.type == "FOLD") {
                await setKeeper(name, Strategy, governanceSigner, wallet_addr);
            }

            /** EARN **/
            await snowglobeEarn(name, SnowGlobe);
            await strategyFold(name, fold, Strategy, governanceSigner);

            /* Gauges */
            await addGauge(name, SnowGlobe, governanceSigner)

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
            //expect(userBal).to.be.equals(BigNumber.from("0x0"));
            let balAfter = await assetContract.connect(walletSigner).balanceOf(snowglobe_addr);
            //expect(balBefore).to.be.lt(balAfter);

            await fastForwardAWeek();

            //let harvestable = await Strategy.getHarvestable();
            //log(`\tHarvestable, pre harvest: ${harvestable.toString()}`);
            let initialBalance = await Strategy.balanceOf();
            await Strategy.connect(walletSigner).harvest();
            await increaseBlock(2);
            //harvestable = await Strategy.getHarvestable();
            //log(`\tHarvestable, post harvest: ${harvestable.toString()}`);

            return [amt, initialBalance];
        };

        it("user wallet contains asset balance", async function() {
            await userWalletAssetBalance(txnAmt, assetContract, walletSigner);
        });

        it("Globe initialized with zero balance for user", async function() {
            await globeHasBalance(SnowGlobe, walletSigner);
        });

        it("Controller globe to be configured correctly", async function() {
            await controllerGlobeConfigure(Controller, asset_addr, snowglobe_addr);
        });

        if (test_case.type != "FOLD") {
            it("Controller strategy to be configured correctly", async () => {
                await controllerStrategyConfigure(Controller, asset_addr, strategy_addr)
            });
        }

        it("Should be able to deposit/withdraw money into globe", async function() {
            await globeDepositWithdraw(assetContract, SnowGlobe, walletSigner);
        });

        it("Harvests should make some money!", async function() {
            await harvestsMakeMoney(Strategy, harvester);
        });

        it("Strategy loaded with initial balance", async function() {
            await strategyLoadedWithBalance(assetContract, SnowGlobe, Strategy, walletSigner);
        });

        it("Users should earn some money!", async function() {
            await usersEarnMoney(assetContract, SnowGlobe, Strategy, walletSigner, txnAmt, slot)
        });

        // Issue raised at: https://github.com/Snowball-Finance/protocol/issues/76
        it("should take no commission when fees not set", async function() {
            await takeNoFees(assetContract, SnowGlobe, Strategy, walletSigner, timelockSigner, txnAmt, slot);
        });

        it("should take some commission when fees are set", async function() {
            await takeSomeFees(harvester, assetContract, SnowGlobe, Strategy, walletSigner, timelockSigner, txnAmt, slot);
        });


    });

};

