const { ethers, network } = require("hardhat");
import chai from "chai";
import { expect } from "chai";
import { BigNumber } from "@ethersproject/bignumber";
import {
    Contract,
    ContractFactory,
    Signer
} from "ethers";
import {
    snowball_addr, treasury_addr,
    WAVAX_ADDR
} from "./static";
import { log } from "./log";
import {
    overwriteTokenAmount,
    increaseTime,
    increaseBlock,
    fastForwardAWeek,
    returnWalletBal,
    returnBal,
    printBals,
    getBalances,
} from "./helpers";


export async function userWalletAssetBalance(txnAmt: string, assetContract: Contract, walletSigner: Signer) {
    let BNBal = await assetContract.balanceOf(await walletSigner.getAddress());
    const BN = ethers.BigNumber.from(txnAmt)._hex.toString();
    expect(BNBal).to.be.equals(BN);
}

export async function globeHasBalance(SnowGlobe: Contract, walletSigner: Signer) {
    let BNBal = await SnowGlobe.balanceOf(await walletSigner.getAddress());
    expect(BNBal).to.be.equals(BigNumber.from("0x0"));
}

export async function controllerGlobeConfigure(Controller: Contract, asset_addr: string, snowglobe_addr: string) {
    expect(await Controller.globes(asset_addr)).to.contains(snowglobe_addr);
}

export async function controllerStrategyConfigure(Controller: Contract, asset_addr: string, strategy_addr: string) {
    expect(await Controller.strategies(asset_addr)).to.be.equals(strategy_addr);
}

export async function harvestsMakeMoney(Strategy: Contract, harvester: Function) {
    let initialBalance;
    [, initialBalance] = await harvester();

    let newBalance = await Strategy.balanceOf();
    log(`initial balance: ${initialBalance}`);
    log(`new balance: ${newBalance}`);
    expect(newBalance).to.be.gt(initialBalance);
}

export async function globeDepositWithdraw(assetContract: Contract, SnowGlobe: Contract, walletSigner: Signer, txnAmt = "2500000000000000000000000000") {
    let snowglobe_addr = SnowGlobe.address;
    let wallet_addr = await walletSigner.getAddress();
    await assetContract.approve(snowglobe_addr, txnAmt);
    let balBefore = await assetContract.connect(walletSigner).balanceOf(snowglobe_addr);
    await SnowGlobe.connect(walletSigner).depositAll();

    let userBal = await assetContract.connect(walletSigner).balanceOf(wallet_addr);
    expect(userBal).to.be.equals(BigNumber.from("0x0"));

    let balAfter = await assetContract.connect(walletSigner).balanceOf(snowglobe_addr);
    expect(balBefore).to.be.lt(balAfter);

    await SnowGlobe.connect(walletSigner).withdrawAll();

    userBal = await assetContract.connect(walletSigner).balanceOf(wallet_addr);
    expect(userBal).to.be.gt(BigNumber.from("0x0"));
}

export async function strategyLoadedWithBalance(assetContract: Contract, SnowGlobe: Contract, Strategy: Contract, walletSigner: Signer, txnAmt = "2500000000000000000000000000") {

    let snowglobe_addr = SnowGlobe.address;
    await assetContract.approve(snowglobe_addr, txnAmt);
    await SnowGlobe.connect(walletSigner).depositAll();

    await SnowGlobe.connect(walletSigner).earn();

    let strategyBalance = await Strategy.balanceOf();
    expect(strategyBalance).to.not.be.equals(BigNumber.from("0x0"));
}

export async function changeFeeDistributor(Strategy: Contract, governanceSigner: Signer, wallet_addr: string) {
    await Strategy.connect(governanceSigner).setFeeDistributor(wallet_addr);
    const feeDistributor = await Strategy.feeDistributor();
    expect(feeDistributor).to.be.equals(wallet_addr);
}

export async function changeKeepAmountForFees(Strategy: Contract, timelockSigner: Signer) {
    await Strategy.connect(timelockSigner).setKeep(10);
    let keep = await Strategy.keep();
    expect(keep).to.be.equals(10);
}

export async function usersEarnMoney(assetContract: Contract, SnowGlobe: Contract, Strategy: Contract, walletSigner: Signer, txnAmt: string, slot: number) {
    let asset_addr = assetContract.address
    let snowglobe_addr = SnowGlobe.address
    let wallet_addr = await walletSigner.getAddress()

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
}

export async function takeNoFees(assetContract: Contract, SnowGlobe: Contract, Strategy: Contract, walletSigner: Signer, timelockSigner: Signer, txnAmt: string, slot: number) {
    let asset_addr = assetContract.address
    let snowglobe_addr = SnowGlobe.address
    let wallet_addr = await walletSigner.getAddress()

    await overwriteTokenAmount(asset_addr, wallet_addr, txnAmt, slot);
    let amt = await assetContract.connect(walletSigner).balanceOf(wallet_addr);

    await assetContract.connect(walletSigner).approve(snowglobe_addr, amt);
    await SnowGlobe.connect(walletSigner).deposit(amt);
    await SnowGlobe.connect(walletSigner).earn();

    await fastForwardAWeek();

    // Set PerformanceTreasuryFee
    await Strategy.connect(timelockSigner).setPerformanceTreasuryFee(0);

    // Set KeepPNG
    await Strategy.connect(timelockSigner).setKeep(0);
    let snobContract = await ethers.getContractAt("ERC20", snowball_addr, walletSigner);

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
    log(`\t💸Snowglobe profit after harvest: ${earnt.toString()}`);
    log(`\t💸Treasury profit after harvest:  ${earntTTreasury.toString()}`);
    log(`\t💸Snowball token accrued : ${snobAccrued}`);
    expect(snobAccrued).to.be.lt(1);
    expect(earntTTreasury).to.be.lt(1);
}

export async function takeSomeFees(harvester: Function, assetContract: Contract, SnowGlobe: Contract, Strategy: Contract, walletSigner: Signer, timelockSigner: Signer, txnAmt: string, slot: number) {
    let asset_addr = assetContract.address
    let snowglobe_addr = SnowGlobe.address
    let wallet_addr = await walletSigner.getAddress()

    // Set PerformanceTreasuryFee
    await Strategy.connect(timelockSigner).setPerformanceTreasuryFee(0);
    // Set KeepPNG
    await Strategy.connect(timelockSigner).setKeep(1000);

    let snobContract = await ethers.getContractAt("ERC20", snowball_addr, walletSigner);

    const globeBefore = await SnowGlobe.balance();
    const treasuryBefore = await assetContract.connect(walletSigner).balanceOf(treasury_addr);
    const snobBefore = await snobContract.balanceOf(treasury_addr);
    log(`snobBefore: ${snobBefore.toString()}`);

    let initialBalance;
    [, initialBalance] = await harvester();

    let newBalance = await Strategy.balanceOf();
    log(`initial balance: ${initialBalance}`);
    log(`new balance: ${newBalance}`);

    const globeAfter = await SnowGlobe.balance();
    const treasuryAfter = await assetContract.connect(walletSigner).balanceOf(treasury_addr);
    const snobAfter = await snobContract.balanceOf(treasury_addr);
    log(`snobAfter: ${snobAfter.toString()}`);
    const earnt = globeAfter.sub(globeBefore);
    const earntTTreasury = treasuryAfter.sub(treasuryBefore);
    const snobAccrued = snobAfter.sub(snobBefore);
    log(`\t💸Snowglobe profit after harvest: ${earnt.toString()}`);
    log(`\t💸Treasury profit after harvest:  ${earntTTreasury.toString()}`);
    log(`\t💸Snowball token accrued : ${snobAccrued}`);
    expect(snobAccrued).to.be.gt(1);
    // expect(earntTTreasury).to.be.gt(BigNumber.from(1));
}


export async function zapInToken(txnAmt: string, token: Contract, lp_token: Contract, SnowGlobe: Contract, Zapper: Contract, walletSigner: Signer) {
    const wallet_addr = await walletSigner.getAddress();
    const snowglobe_addr = SnowGlobe.address;
    const amt = ethers.utils.parseEther(txnAmt);
    let [user1, globe1] = await getBalances(token, lp_token, wallet_addr, SnowGlobe);
    let symbol = await token.symbol;

    log(`The value of ${symbol} before doing anything is: ${user1}`);

    await Zapper.zapIn(snowglobe_addr, 0, token.address, amt);
    let [user2, globe2] = await getBalances(token, lp_token, wallet_addr, SnowGlobe);
    printBals(`Zap ${txnAmt}`, globe2, user2);

    log(`The value of token ${symbol} after zapping in is: ${user2}`);
    log(`the difference between both ${symbol}'s : ${user1 - user2}`);

    await SnowGlobe.connect(walletSigner).earn();
    let [user3, globe3] = await getBalances(token, lp_token, wallet_addr, SnowGlobe);
    printBals("Call earn()", globe3, user3);

    expect((user1 - user2) / Number(txnAmt)).to.be.greaterThan(0.98);
    expect(globe2).to.be.greaterThan(globe1);
    expect(globe2).to.be.greaterThan(globe3);
}

export async function zapOutToken(txnAmt: string, token: Contract, lp_token: Contract, Gauge: Contract, SnowGlobe: Contract, Zapper: Contract, walletSigner: Signer) {
    const wallet_addr = await walletSigner.getAddress();
    const snowglobe_addr = SnowGlobe.address;
    const amt = ethers.utils.parseEther(txnAmt);
    let symbol = await token.symbol;

    log(`The amount we are zapping in with is: ${amt}`);
    //let receipt = await Gauge.balanceOf(wallet_addr);
    let balA = (token.address != WAVAX_ADDR) ? await returnBal(token, wallet_addr) : await returnWalletBal(wallet_addr);

    log(`The balance of ${symbol} before anything is done to it: ${balA}`);

    await Zapper.zapIn(snowglobe_addr, 0, token.address, amt);
    let receipt = await Gauge.balanceOf(wallet_addr);
    let balABefore = (token.address != WAVAX_ADDR) ? await returnBal(token, wallet_addr) : await returnWalletBal(wallet_addr);

    log(`The balance of ${symbol} before we zap out is: ${balABefore}`);

    await SnowGlobe.connect(walletSigner).earn();
    await Gauge.connect(walletSigner).withdrawAll();
    await Zapper.zapOutAndSwap(snowglobe_addr, receipt, token.address, 0);

    let balAAfter = (token.address != WAVAX_ADDR) ? await returnBal(token, wallet_addr) : await returnWalletBal(wallet_addr);
    let receipt2 = await Gauge.balanceOf(wallet_addr);

    log(`The balance of ${symbol} after we zap out is: ${balAAfter}`);
    log(`The difference of ${symbol} before and after is: ${balAAfter - balABefore}`);

    expect(receipt2).to.be.equals(0);
    (token.address != WAVAX_ADDR) ?
        expect(balAAfter - balABefore).to.roughly(0.01).deep.equal(Number(txnAmt)) :
        expect(balAAfter).to.be.greaterThan(balABefore);

}


