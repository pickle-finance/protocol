/* eslint-disable no-undef */
const hre = require("hardhat");
const { ethers, network } = require("hardhat");
const chai = require("chai");
const { BigNumber } = require("@ethersproject/bignumber");
const {increaseTime, overwriteTokenAmount, increaseBlock} = require("./utils/helpers");
const { expect } = chai;
const {setupSigners} = require("./utils/actors")

describe("Sample Folding Strat", async () => {

    const walletAddr = process.env.WALLET_ADDR;
    //const walletAddr = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
    const txnAmt = "300000000000";
    const assetAddr = "0x50b7545627a5162F82A992c33b87aDc75187B218";
    const snowglobeAddr = "0x8FA104f65BDfddEcA211867b77e83949Fc9d8b44";
    const strategyAddr= "0x3DD8c4BB2e3fC4dC42e5D2765093aE9325E49ed6";

    let assetContract,controllerContract;
    let governanceSigner, strategistSigner, controllerSigner, timelockSigner;
    let globeContract, strategyContract;
    let strategyBalance;

    before( async () => {
        await network.provider.send('hardhat_impersonateAccount', [walletAddr]);

        walletSigner = ethers.provider.getSigner(walletAddr);
        [timelockSigner,strategistSigner,controllerSigner,governanceSigner] = await setupSigners();
       
        await overwriteTokenAmount(assetAddr,walletAddr,txnAmt);
    
        assetContract = await ethers.getContractAt("ERC20",assetAddr,walletSigner);
        strategyContract = await ethers.getContractAt("StrategyBenqiWbtc", strategyAddr,  governanceSigner);
        globeContract = await ethers.getContractAt("SnowGlobeBenqiWbtc", snowglobeAddr,  governanceSigner);
        controllerContract = await ethers.getContractAt("ControllerV4", await controllerSigner.getAddress(),  governanceSigner);
        await strategyContract.whitelistHarvester(walletAddr);
       
    });

    it("user wallet contains asset balance", async () =>{
        let BNBal = await assetContract.balanceOf(await walletSigner.getAddress());
        const BN = ethers.BigNumber.from(txnAmt)._hex.toString();
        expect(BNBal).to.be.equals(BN);
    });

    it("Strategy loaded with initial balance", async () =>{
        strategyBalance = await strategyContract.balanceOf();
        //expect(strategyBalance).to.be.equals(BigNumber.from("0x0"));
    });

    it("Globe initialized with zero balance for user", async () =>{
        let BNBal = await globeContract.balanceOf(walletSigner.getAddress());
        expect(BNBal).to.be.equals(BigNumber.from("0x0"));
    });

    it("Should be able to be configured correctly", async () => {
        expect(await controllerContract.globes(assetAddr)).to.be.equals(snowglobeAddr);
        expect(await controllerContract.strategies(assetAddr)).to.be.equals(strategyAddr);
    });

    it("Should be able to deposit/withdraw money into globe", async () => {
        await assetContract.approve(snowglobeAddr,"25000000000000000000");
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
        let amt = await assetContract.connect(walletSigner).balanceOf(walletAddr);
        await assetContract.connect(walletSigner).approve(snowglobeAddr,amt);
        await globeContract.connect(walletSigner).deposit(amt);
        await globeContract.connect(walletSigner).earn();
        await increaseTime(60 * 60 * 24 * 15);

        let initialBalance = await strategyContract.balanceOf();

        await strategyContract.connect(walletSigner).harvest();
        let newBalance = await strategyContract.balanceOf();
        expect(newBalance).to.be.gt(initialBalance);
    });

    it("Users should earn some money!", async () => {
        await overwriteTokenAmount(assetAddr,walletAddr,txnAmt);

        let amt = await assetContract.connect(walletSigner).balanceOf(walletAddr);
        await assetContract.connect(walletSigner).approve(snowglobeAddr,amt);
        await globeContract.connect(walletSigner).deposit(amt);
        await globeContract.connect(walletSigner).earn();
        await increaseTime(60 * 60 * 24 * 15);
        await strategyContract.connect(walletSigner).harvest();

        await globeContract.connect(walletSigner).withdrawAll();
        let newAmt = await assetContract.connect(walletSigner).balanceOf(walletAddr);

        expect(amt.mul(2)).to.be.lt(newAmt);
    });

    


});
