/* eslint-disable no-undef */
const hre = require("hardhat");
const { ethers } = require("hardhat");
const chai = require("chai");
const { BigNumber } = require("@ethersproject/bignumber");
const { expect } = chai;

describe("Sample Folding Strat", async () => {

    const assetAddr = "0x50b7545627a5162F82A992c33b87aDc75187B218";
    const whaleAddr = "0xd5a37dC5C9A396A03dd1136Fc76A1a02B1c88Ffa";
    const walletAddr = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
    const txnAmt = "3";



    let assetSigner
    let timelockSigner
    let strategistSigner
    let governanceSigner 
    let controllerSigner
    let walletSigner
    let assetContract
    let deployedStrat
    let deployedGlobe

    before( async () => {
        await ethers.provider.send('hardhat_impersonateAccount', [assetAddr]);
        await ethers.provider.send('hardhat_impersonateAccount', ['0xdbc195a0ed72c0b059f8906e97a90636d2b6409f']);
        await ethers.provider.send('hardhat_impersonateAccount', ['0xc9a51fb9057380494262fd291aed74317332c0a2']);
        await ethers.provider.send('hardhat_impersonateAccount', ['0xc9a51fb9057380494262fd291aed74317332c0a2']);
        await ethers.provider.send('hardhat_impersonateAccount', ['0x294aB3200ef36200db84C4128b7f1b4eec71E38a']);
        await ethers.provider.send('hardhat_impersonateAccount', [walletAddr]);
        await ethers.provider.send('hardhat_impersonateAccount', ['0xc9a51fB9057380494262fd291aED74317332C0a2']);

        assetSigner = ethers.provider.getSigner(assetAddr);
        timelockSigner = ethers.provider.getSigner("0xdbc195a0ed72c0b059f8906e97a90636d2b6409f")
        strategistSigner = ethers.provider.getSigner("0xc9a51fb9057380494262fd291aed74317332c0a2")
        governanceSigner = ethers.provider.getSigner("0x294aB3200ef36200db84C4128b7f1b4eec71E38a")
        controllerSigner = ethers.provider.getSigner("0xf7B8D9f8a82a7a6dd448398aFC5c77744Bd6cb85")
        walletSigner = ethers.provider.getSigner(walletAddr);
        ownerSigner = ethers.provider.getSigner("0xc9a51fB9057380494262fd291aED74317332C0a2")

        // for sending to contract
        //await walletSigner.sendTransaction({to: whaleAddr,value: 1});

        assetContract = await ethers.getContractAt("ERC20",assetAddr,walletSigner);
        const index = ethers.utils.solidityKeccak256(["uint256", "uint256"],[walletAddr, 0]);
        const BN = ethers.BigNumber.from(txnAmt)._hex.toString();
        const number = ethers.utils.hexZeroPad(BN,32);
        await ethers.provider.send("hardhat_setStorageAt", [assetAddr, index, number]);
    
        
        const stratFactory = await ethers.getContractFactory("StrategyBenqiWbtc");
        deployedStrat = await stratFactory.deploy(governanceSigner.getAddress(), ownerSigner.getAddress(), controllerSigner.getAddress(), ownerSigner.getAddress());

        const globeFactory = await ethers.getContractFactory("SnowGlobeBenqiWbtc");
        deployedGlobe = await globeFactory.deploy("0x49D5c2BdFfac6CE2BFdB6640F4F80f226bc10bAB", governanceSigner.getAddress(), ownerSigner.getAddress(), controllerSigner.getAddress());
    });

    it("user wallet contains asset balance", async () =>{
        let BNBal = await assetContract.balanceOf(walletSigner.getAddress());
        const BN = ethers.BigNumber.from(txnAmt)._hex.toString();
        expect(BNBal).to.be.equals(BN);
    });

    it("Strategy initialized with zero balance", async () =>{
        let BNBal = await deployedStrat.balanceOf();
        expect(BNBal).to.be.equals(BigNumber.from("0x0"));
    });

    it("Globe initialized with zero balance", async () =>{
        let BNBal = await deployedGlobe.balanceOf(walletSigner.getAddress());
        expect(BNBal).to.be.equals(BigNumber.from("0x0"));
    });


});
