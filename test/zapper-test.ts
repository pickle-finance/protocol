/** NOTES ABOUT THIS TEST FILE
-- Only designed for testing against LPs ***/
const { ethers } = require("hardhat");
import chai from "chai";
import { solidity } from "ethereum-waffle";
import chaiRoughly from 'chai-roughly';
import chaiAsPromised from 'chai-as-promised';
chai.use(solidity);
chai.use(chaiAsPromised);
chai.use(chaiRoughly);
import { expect } from "chai"
import {
    increaseTime, overwriteTokenAmount, increaseBlock,
    returnSigner, fastForwardAWeek, findSlot, returnController,
    getLpSlot, getPoolABI, getBalancesAvax,
    getBalances, printBals, returnBal, returnWalletBal
} from "./utils/helpers";
import {
    setupSigners,
    MAX_UINT256,
    WAVAX_ADDR
} from "./utils/static";
import { setupMockSnowGlobe } from "./mocks/SnowGlobe";
import { setupMockGauge } from "./mocks/Gauge";
import { setupMockZapper } from "./mocks/Zapper";
import {
    Contract,
    Signer,
    BigNumber
} from "ethers";
import {
    zapInToken, zapOutToken
} from "./utils/its";
import { log } from "./utils/log";

const txnAmt = "35000000000000000000000";
const gauge_proxy_addr: string = "0x215D5eDEb6A6a3f84AE9d72962FEaCCdF815BF27";
const poolTokenABI = require('./abis/PoolTokenABI.json');

export function doZapperTests(
    name: string,
    snowglobe_addr: string,
    pool_type: string,
    gauge_addr = "",
    controller = "main",
) {

    describe(`${name} Zapper Integration Tests`, () => {
        let snapshotId: string;
        let assetAddr: string;
        let zapper_addr: string;
        let controllerAddr: string;
        let controllerSigner: Signer;
        let walletSigner: Signer;
        let LPToken: Contract;
        let TokenA: Contract;
        let TokenB: Contract;
        let Gauge: Contract;
        let SnowGlobe: Contract;
        let Controller: Contract;
        let Zapper: Contract;

        let timelockSigner: Signer
        let strategistSigner: Signer
        let governanceSigner: Signer

        const wallet_addr = process.env.WALLET_ADDR === undefined ? '' : process.env.WALLET_ADDR;

        //These reset the state after each test is executed 
        beforeEach(async () => {
            snapshotId = await ethers.provider.send('evm_snapshot');
        })

        afterEach(async () => {
            await ethers.provider.send('evm_revert', [snapshotId]);
        })

        before(async () => {
            // Setup Signers
            walletSigner = await returnSigner(wallet_addr);
            [timelockSigner, strategistSigner, governanceSigner] = await setupSigners();
            controllerAddr = returnController(controller);
            controllerSigner = await returnSigner(controllerAddr);

            // Deploy Snowglobe Contract
            const snowglobeName = `SnowGlobe${name}`;
            // assumes always given a snowglobe address
            SnowGlobe = await setupMockSnowGlobe(
                snowglobeName,
                snowglobe_addr,
                "",
                Controller,
                timelockSigner,
                governanceSigner
            );

            // Derive Relevant Tokens
            let lp_token_addr = await SnowGlobe.token();
            LPToken = await ethers.getContractAt(getPoolABI(pool_type), lp_token_addr, walletSigner);
            let slot = getLpSlot(pool_type);
            await overwriteTokenAmount(lp_token_addr, wallet_addr, txnAmt, slot);

            let token_A_addr = await LPToken.token0();
            TokenA = await ethers.getContractAt("contracts/lib/erc20.sol:IERC20", token_A_addr, walletSigner);
            let slotA = findSlot(token_A_addr);
            await overwriteTokenAmount(token_A_addr, wallet_addr, txnAmt, slotA);

            let token_B_addr = await LPToken.token1();
            TokenB = await ethers.getContractAt("contracts/lib/erc20.sol:IERC20", token_B_addr, walletSigner);
            let slotB = findSlot(token_B_addr);
            await overwriteTokenAmount(token_B_addr, wallet_addr, txnAmt, slotB);

            // Deploy Gauge + Setup with GaugeProxy
            Gauge = await setupMockGauge(
                name,
                gauge_addr,
                lp_token_addr,
                SnowGlobe,
                governanceSigner,
                gauge_proxy_addr,
            );
            gauge_addr = Gauge.address;

            // Deploy Zapper
            Zapper = await setupMockZapper(pool_type);
            zapper_addr = Zapper.address;

            //Approvals
            await TokenA.approve(zapper_addr, MAX_UINT256);
            await TokenB.approve(zapper_addr, MAX_UINT256);
            await SnowGlobe.connect(walletSigner).approve(zapper_addr, MAX_UINT256);
            await SnowGlobe.connect(walletSigner).approve(gauge_addr, MAX_UINT256);
        });

        describe("When setup is completed..", async () => {
            it("..contracts are loaded", async () => {
                expect(snowglobe_addr).to.not.be.empty;
                expect(zapper_addr).to.not.be.empty;
                expect(gauge_addr).to.not.be.empty;
                expect(LPToken.address).to.not.be.empty;
                expect(TokenA.address).to.not.be.empty;
                expect(TokenB.address).to.not.be.empty;
                log(`\tToken Addresses are ${TokenA.address} and ${TokenB.address}`);
            })

            it("..user has positive balances for tokens and LP", async () => {
                let lpBal = ethers.utils.formatEther(await LPToken.balanceOf(wallet_addr));
                let aBal = ethers.utils.formatEther(await TokenA.balanceOf(wallet_addr));
                let bBal = ethers.utils.formatEther(await TokenB.balanceOf(wallet_addr));
                expect(Number(lpBal), "LP Balance empty").to.be.greaterThan(0);
                expect(Number(aBal), "TokenA Balance empty").to.be.greaterThan(0);
                expect(Number(bBal), "TokenB Balance empty").to.be.greaterThan(0);

            })
        })

        describe("When depositing..", async () => {
            it("..can zap in with TokenA", async () => {
                const txnAmt = "33";
                await zapInToken(txnAmt, TokenA, LPToken, SnowGlobe, Zapper, walletSigner);
            })

            it("..can zap in with TokenB", async () => {
                const txnAmt = "66";
                await zapInToken(txnAmt, TokenB, LPToken, SnowGlobe, Zapper, walletSigner);
            })

            it("..can zap in with AVAX", async () => {
                const txnAmt = "55";
                const amt = ethers.utils.parseEther(txnAmt);
                let [user1, globe1] = await getBalancesAvax(LPToken, walletSigner, SnowGlobe);
                printBals("Original", globe1, user1);

                log(`The value of A before zapping in with AVAX is: ${user1}`);

                await Zapper.zapInAVAX(snowglobe_addr, 0, TokenB.address, { value: amt });
                let [user2, globe2] = await getBalancesAvax(LPToken, walletSigner, SnowGlobe);
                printBals(`Zap ${txnAmt} AVAX`, globe2, user2);

                log(`The value of token A after zapping in with Avax is: ${user2}`);
                log(`the difference between both A's : ${user1 - user2}`);

                await SnowGlobe.connect(walletSigner).earn();
                let [user3, globe3] = await getBalancesAvax(LPToken, walletSigner, SnowGlobe);
                printBals("Call earn()", globe3, user3);

                expect((user1 - user2) / Number(txnAmt)).to.be.greaterThan(0.98);
                expect(globe2).to.be.greaterThan(globe1);
                expect(globe2).to.be.greaterThan(globe3);
            })
        })

        describe("When withdrawing..", async () => {
            it("..can zap out into TokenA", async () => {
                const txnAmt = "24";
                await zapOutToken(txnAmt, TokenA, LPToken, Gauge, SnowGlobe, Zapper, walletSigner);
            })

            it("..can zap out into TokenB", async () => {
                const txnAmt = "35";
                await zapOutToken(txnAmt, TokenB, LPToken, Gauge, SnowGlobe, Zapper, walletSigner);
            })

            it("..can zap out equally", async () => {
                const txnAmt = "45";
                const amt = ethers.utils.parseEther(txnAmt);

                log(`The amount we are zapping in with is: ${amt}`);
                let balA = (TokenA.address != WAVAX_ADDR) ? await returnBal(TokenA, wallet_addr) : await returnWalletBal(wallet_addr);
                let balB = (TokenB.address != WAVAX_ADDR) ? await returnBal(TokenB, wallet_addr) : await returnWalletBal(wallet_addr);
                log(`The balance of A and B before we do anything is ${balA} and ${balB}`);

                await Zapper.zapIn(snowglobe_addr, 0, TokenA.address, amt);
                let receipt = await Gauge.balanceOf(wallet_addr);
                let balABefore = (TokenA.address != WAVAX_ADDR) ? await returnBal(TokenA, wallet_addr) : await returnWalletBal(wallet_addr);
                let balBBefore = (TokenB.address != WAVAX_ADDR) ? await returnBal(TokenB, wallet_addr) : await returnWalletBal(wallet_addr);

                log(`The balance of A before we zap out is: ${balABefore}`);
                log(`The balance of B before we zap out is: ${balBBefore}`);

                await SnowGlobe.connect(walletSigner).earn();
                await Gauge.connect(walletSigner).withdrawAll();
                await Zapper.zapOut(snowglobe_addr, receipt);
                let receipt2 = await Gauge.balanceOf(wallet_addr);
                let balAAfter = (TokenA.address != WAVAX_ADDR) ? await returnBal(TokenA, wallet_addr) : await returnWalletBal(wallet_addr);
                let balBAfter = (TokenB.address != WAVAX_ADDR) ? await returnBal(TokenB, wallet_addr) : await returnWalletBal(wallet_addr);
                log(`The balance of A after we zap out is: ${balAAfter}`);
                log(`The balance of B after we zap out is: ${balBAfter}`);

                log(`The difference of A before and after is: ${balAAfter - balABefore}`);
                log(`The difference of B before and after is: ${balBAfter - balBBefore}`);

                log(`The thing we want our balance to be equal to is: ${Number(txnAmt) / 2}`);

                (TokenA.address != WAVAX_ADDR) ?
                    expect(balAAfter - balABefore, "Incorrect TokenA").to.roughly(0.01).deep.equal(Number(txnAmt) / 2) :
                    expect(balAAfter).to.be.greaterThan(balABefore);
                (TokenB.address != WAVAX_ADDR) ?
                    expect(balBAfter - balBBefore, "Incorrect TokenB").to.roughly(0.01).deep.equal(Number(txnAmt) / 2) :
                    expect(balBAfter).to.be.greaterThan(balBBefore);
                expect(receipt2).to.be.equals(0);
            })
        })

        describe("When minimum amounts unmet..", async () => {
            it("..reverts on zap in token", async () => {
                const txnAmt = "100";
                const amt = ethers.utils.parseEther(txnAmt);

                expect(Zapper.zapIn(snowglobe_addr, amt, TokenA.address, amt)).to.be.reverted;
            })
            it("..reverts on zap in avax", async () => {
                const txnAmt = "1";
                const txnAmt2 = "5";
                const amt = ethers.utils.parseEther(txnAmt);
                const amt2 = ethers.utils.parseEther(txnAmt2);

                //amt was too large that it succeeds when reaching line 60 of the zapper contract. However, we want it to fail
                log(`the token A address is ${TokenA.address}`);
                log(`the token B address is ${TokenB.address}`);

                await expect(Zapper.zapInAVAX(snowglobe_addr, amt2, TokenA.address, { value: txnAmt })).to.be.reverted;
            })

            it("..reverts on zap out token", async () => {
                const txnAmt = "35";
                const amt = ethers.utils.parseEther(txnAmt);

                await Zapper.zapIn(snowglobe_addr, 0, TokenB.address, amt);
                let receipt = await Gauge.balanceOf(wallet_addr);
                await SnowGlobe.connect(walletSigner).earn();
                await Gauge.connect(walletSigner).withdrawAll();
                await expect(Zapper.zapOutAndSwap(snowglobe_addr, receipt, TokenB.address, amt)).to.be.reverted;
            })

            //missing
            it("..reverts on zap out avax", async () => {
            })
        })
    })
}
