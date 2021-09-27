/* eslint-disable no-undef */
const hre = require("hardhat");
const { ethers } = require("hardhat");
const chai = require("chai");
const { BigNumber } = require("@ethersproject/bignumber");
const { expect } = chai;

describe("Sample Folding Strat", async () => {

    const assetAddr = "0x50b7545627a5162F82A992c33b87aDc75187B218";
    const walletAddr = "0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266";
    const controllerAddr = "0xf7B8D9f8a82a7a6dd448398aFC5c77744Bd6cb85";
    const timelockAddr = "0xdbc195a0ed72c0b059f8906e97a90636d2b6409f";
    const governanceAddr = "0x294aB3200ef36200db84C4128b7f1b4eec71E38a";
    const strategistAddr = "0xc9a51fb9057380494262fd291aed74317332c0a2";
    const snowglobeAddr = "0x8FA104f65BDfddEcA211867b77e83949Fc9d8b44";
    const txnAmt = "30000000";



    let assetSigner
    let timelockSigner
    let strategistSigner
    let governanceSigner 
    let controllerSigner
    let walletSigner
    let assetContract
    let deployedStrat
    let deployedGlobe
    let snowglobeContract
    let strategyContract
    let controllerContract

    before( async () => {
        await ethers.provider.send('hardhat_impersonateAccount', [assetAddr]);
        await ethers.provider.send('hardhat_impersonateAccount', [timelockAddr]);
        await ethers.provider.send('hardhat_impersonateAccount', [strategistAddr]);
        await ethers.provider.send('hardhat_impersonateAccount', [controllerAddr]);
        await ethers.provider.send('hardhat_impersonateAccount', [governanceAddr]);
        await ethers.provider.send('hardhat_impersonateAccount', [walletAddr]);
        

        assetSigner = ethers.provider.getSigner(assetAddr);
        timelockSigner = ethers.provider.getSigner(timelockAddr);
        strategistSigner = ethers.provider.getSigner(strategistAddr);
        governanceSigner = ethers.provider.getSigner(governanceAddr);
        controllerSigner = ethers.provider.getSigner(controllerAddr);
        walletSigner = ethers.provider.getSigner(walletAddr);

        // for sending to contract
        //await walletSigner.sendTransaction({to: whaleAddr,value: 1});

        assetContract = await ethers.getContractAt("ERC20",assetAddr,walletSigner);
        const index = ethers.utils.solidityKeccak256(["uint256", "uint256"],[walletAddr, 0]);
        const BN = ethers.BigNumber.from(txnAmt)._hex.toString();
        const number = ethers.utils.hexZeroPad(BN,32);
        await ethers.provider.send("hardhat_setStorageAt", [assetAddr, index, number]);


        const stratFactory = await ethers.getContractFactory("StrategyBenqiWbtc");
        deployedStrat = await stratFactory.deploy(governanceAddr, strategistAddr, controllerAddr, timelockAddr);

        // Controller doesn't allow new globes
        // const globeFactory = await ethers.getContractFactory("SnowGlobeBenqiWbtc");
        // deployedGlobe = await globeFactory.deploy(assetAddr, governanceAddr, timelockAddr, controllerAddr);

        globeContract = await ethers.getContractAt("SnowGlobeBenqiWbtc", snowglobeAddr, governanceSigner);
        controllerContract = await ethers.getContractAt("ControllerV4", controllerAddr, governanceSigner);

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

    it("Globe initialized with zero balance for user", async () =>{
        let BNBal = await globeContract.balanceOf(walletSigner.getAddress());
        expect(BNBal).to.be.equals(BigNumber.from("0x0"));
    });

    it("Should be able to be configured correctly", async () => {
        await controllerContract.connect(timelockSigner).approveStrategy(assetAddr,deployedStrat.address);
        await controllerContract.connect(strategistSigner).setStrategy(assetAddr,deployedStrat.address);
        // await controllerContract.connect(strategistSigner).setGlobe(assetAddr,snowglobeAddr);

        expect(await controllerContract.globes(assetAddr)).to.be.equals(globeContract.address);
        expect(await controllerContract.strategies(assetAddr)).to.be.equals(deployedStrat.address);
    });

    it("Should be able to deposit money into globe", async () => {

        
        await assetContract.approve(snowglobeAddr,"25000000000000000000");
        await globeContract.depositAll();
        
        
        let Bal1 = await globeContract.balanceOf(walletAddr);
        expect(Bal1).to.be.equals(BigNumber.from("0x0"));

        const Bal2 = await globeContract.available();
        expect(Bal2).to.not.be.equals(BigNumber.from("0x0"));
    });

    it("earns money!", async () => {
        await SnowglobeAsUser.earn()
    });

    


});
