/* eslint-disable no-undef */
const { ethers, network } = require("hardhat");
const chai = require("chai");
const { BigNumber } = require("@ethersproject/bignumber");
const { returnController, overwriteTokenAmount, increaseBlock, returnSigner, fastForwardAWeek, findSlot } = require("./utils/helpers");
const { expect } = chai;
const { setupSigners, snowballAddr, treasuryAddr} = require("./utils/static");

const doSingleStakeTest = (
    name,
    assetAddr,
    snowglobeAddr = "",
    strategyAddr = "",
    controller = "main",
    globeABI = [{ "type": "constructor", "stateMutability": "nonpayable", "inputs": [{ "type": "address", "name": "_token", "internalType": "address" }, { "type": "address", "name": "_governance", "internalType": "address" }, { "type": "address", "name": "_timelock", "internalType": "address" }, { "type": "address", "name": "_controller", "internalType": "address" }] }, { "type": "event", "name": "Approval", "inputs": [{ "type": "address", "name": "owner", "internalType": "address", "indexed": true }, { "type": "address", "name": "spender", "internalType": "address", "indexed": true }, { "type": "uint256", "name": "value", "internalType": "uint256", "indexed": false }], "anonymous": false }, { "type": "event", "name": "Transfer", "inputs": [{ "type": "address", "name": "from", "internalType": "address", "indexed": true }, { "type": "address", "name": "to", "internalType": "address", "indexed": true }, { "type": "uint256", "name": "value", "internalType": "uint256", "indexed": false }], "anonymous": false }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "allowance", "inputs": [{ "type": "address", "name": "owner", "internalType": "address" }, { "type": "address", "name": "spender", "internalType": "address" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "approve", "inputs": [{ "type": "address", "name": "spender", "internalType": "address" }, { "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "available", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "balance", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "balanceOf", "inputs": [{ "type": "address", "name": "account", "internalType": "address" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "address", "name": "", "internalType": "address" }], "name": "controller", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint8", "name": "", "internalType": "uint8" }], "name": "decimals", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "decreaseAllowance", "inputs": [{ "type": "address", "name": "spender", "internalType": "address" }, { "type": "uint256", "name": "subtractedValue", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "deposit", "inputs": [{ "type": "uint256", "name": "_amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "depositAll", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "earn", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "getRatio", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "address", "name": "", "internalType": "address" }], "name": "governance", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "harvest", "inputs": [{ "type": "address", "name": "reserve", "internalType": "address" }, { "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "increaseAllowance", "inputs": [{ "type": "address", "name": "spender", "internalType": "address" }, { "type": "uint256", "name": "addedValue", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "max", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "min", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "string", "name": "", "internalType": "string" }], "name": "name", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "setController", "inputs": [{ "type": "address", "name": "_controller", "internalType": "address" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "setGovernance", "inputs": [{ "type": "address", "name": "_governance", "internalType": "address" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "setMin", "inputs": [{ "type": "uint256", "name": "_min", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "setTimelock", "inputs": [{ "type": "address", "name": "_timelock", "internalType": "address" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "string", "name": "", "internalType": "string" }], "name": "symbol", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "address", "name": "", "internalType": "address" }], "name": "timelock", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "address", "name": "", "internalType": "contract IERC20" }], "name": "token", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "totalSupply", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "transfer", "inputs": [{ "type": "address", "name": "recipient", "internalType": "address" }, { "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "transferFrom", "inputs": [{ "type": "address", "name": "sender", "internalType": "address" }, { "type": "address", "name": "recipient", "internalType": "address" }, { "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "withdraw", "inputs": [{ "type": "uint256", "name": "_shares", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "withdrawAll", "inputs": [] }],
    stratABI = [{ "inputs": [{ "internalType": "address", "name": "_want", "type": "address" }, { "internalType": "address", "name": "_governance", "type": "address" }, { "internalType": "address", "name": "_strategist", "type": "address" }, { "internalType": "address", "name": "_controller", "type": "address" }, { "internalType": "address", "name": "_timelock", "type": "address" }], "stateMutability": "nonpayable", "type": "constructor" }, { "inputs": [], "name": "balanceOf", "outputs": [{ "internalType": "uint256", "name": "", "type": "uint256" }], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "balanceOfPool", "outputs": [{ "internalType": "uint256", "name": "", "type": "uint256" }], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "balanceOfWant", "outputs": [{ "internalType": "uint256", "name": "", "type": "uint256" }], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "controller", "outputs": [{ "internalType": "address", "name": "", "type": "address" }], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "deposit", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [{ "internalType": "address", "name": "_target", "type": "address" }, { "internalType": "bytes", "name": "_data", "type": "bytes" }], "name": "execute", "outputs": [{ "internalType": "bytes", "name": "response", "type": "bytes" }], "stateMutability": "payable", "type": "function" }, { "inputs": [], "name": "feeDistributor", "outputs": [{ "internalType": "address", "name": "", "type": "address" }], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "getName", "outputs": [{ "internalType": "string", "name": "", "type": "string" }], "stateMutability": "pure", "type": "function" }, { "inputs": [], "name": "governance", "outputs": [{ "internalType": "address", "name": "", "type": "address" }], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "harvest", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [{ "internalType": "address", "name": "", "type": "address" }], "name": "harvesters", "outputs": [{ "internalType": "bool", "name": "", "type": "bool" }], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "keep", "outputs": [{ "internalType": "uint256", "name": "", "type": "uint256" }], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "keepMax", "outputs": [{ "internalType": "uint256", "name": "", "type": "uint256" }], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "pangolinRouter", "outputs": [{ "internalType": "address", "name": "", "type": "address" }], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "performanceDevFee", "outputs": [{ "internalType": "uint256", "name": "", "type": "uint256" }], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "performanceDevMax", "outputs": [{ "internalType": "uint256", "name": "", "type": "uint256" }], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "performanceTreasuryFee", "outputs": [{ "internalType": "uint256", "name": "", "type": "uint256" }], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "performanceTreasuryMax", "outputs": [{ "internalType": "uint256", "name": "", "type": "uint256" }], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "png", "outputs": [{ "internalType": "address", "name": "", "type": "address" }], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "revenueShare", "outputs": [{ "internalType": "uint256", "name": "", "type": "uint256" }], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "revenueShareMax", "outputs": [{ "internalType": "uint256", "name": "", "type": "uint256" }], "stateMutability": "view", "type": "function" }, { "inputs": [{ "internalType": "address", "name": "_harvester", "type": "address" }], "name": "revokeHarvester", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [{ "internalType": "address", "name": "_controller", "type": "address" }], "name": "setController", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [{ "internalType": "address", "name": "_feeDistributor", "type": "address" }], "name": "setFeeDistributor", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [{ "internalType": "address", "name": "_governance", "type": "address" }], "name": "setGovernance", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [{ "internalType": "uint256", "name": "_keep", "type": "uint256" }], "name": "setKeep", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [{ "internalType": "uint256", "name": "_performanceDevFee", "type": "uint256" }], "name": "setPerformanceDevFee", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [{ "internalType": "uint256", "name": "_performanceTreasuryFee", "type": "uint256" }], "name": "setPerformanceTreasuryFee", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [{ "internalType": "uint256", "name": "_share", "type": "uint256" }], "name": "setRevenueShare", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [{ "internalType": "address", "name": "_strategist", "type": "address" }], "name": "setStrategist", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [{ "internalType": "address", "name": "_timelock", "type": "address" }], "name": "setTimelock", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [{ "internalType": "uint256", "name": "_withdrawalDevFundFee", "type": "uint256" }], "name": "setWithdrawalDevFundFee", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [{ "internalType": "uint256", "name": "_withdrawalTreasuryFee", "type": "uint256" }], "name": "setWithdrawalTreasuryFee", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [], "name": "snob", "outputs": [{ "internalType": "address", "name": "", "type": "address" }], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "strategist", "outputs": [{ "internalType": "address", "name": "", "type": "address" }], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "timelock", "outputs": [{ "internalType": "address", "name": "", "type": "address" }], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "want", "outputs": [{ "internalType": "address", "name": "", "type": "address" }], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "wavax", "outputs": [{ "internalType": "address", "name": "", "type": "address" }], "stateMutability": "view", "type": "function" }, { "inputs": [{ "internalType": "address", "name": "_harvester", "type": "address" }], "name": "whitelistHarvester", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [{ "internalType": "uint256", "name": "_amount", "type": "uint256" }], "name": "withdraw", "outputs": [], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [{ "internalType": "contractIERC20", "name": "_asset", "type": "address" }], "name": "withdraw", "outputs": [{ "internalType": "uint256", "name": "balance", "type": "uint256" }], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [], "name": "withdrawAll", "outputs": [{ "internalType": "uint256", "name": "balance", "type": "uint256" }], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [{ "internalType": "uint256", "name": "_amount", "type": "uint256" }], "name": "withdrawForSwap", "outputs": [{ "internalType": "uint256", "name": "balance", "type": "uint256" }], "stateMutability": "nonpayable", "type": "function" }, { "inputs": [], "name": "withdrawalDevFundFee", "outputs": [{ "internalType": "uint256", "name": "", "type": "uint256" }], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "withdrawalDevFundMax", "outputs": [{ "internalType": "uint256", "name": "", "type": "uint256" }], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "withdrawalTreasuryFee", "outputs": [{ "internalType": "uint256", "name": "", "type": "uint256" }], "stateMutability": "view", "type": "function" }, { "inputs": [], "name": "withdrawalTreasuryMax", "outputs": [{ "internalType": "uint256", "name": "", "type": "uint256" }], "stateMutability": "view", "type": "function" }],
    txnAmt = "250000000000000000000000",
    ) => {

    const walletAddr = process.env.WALLET_ADDR;
    const slot = findSlot(assetAddr);
    let assetContract, controllerContract;
    let governanceSigner, strategistSigner, controllerSigner, timelockSigner;
    let globeContract, strategyContract;
    let strategyBalance, controllerAddr;
    
    describe("Folding Strategy tests for: " + name, async () => {

        //These reset the state after each test is executed 
        beforeEach(async () => {
            snapshotId = await ethers.provider.send('evm_snapshot');
        });
    
        afterEach(async () => {
            await ethers.provider.send('evm_revert', [snapshotId]);
        });

        before(async () => {
            const strategyName = `Strategy${name}`;
            const snowglobeName = `SnowGlobe${name}`;

            [timelockSigner, strategistSigner, governanceSigner] = await setupSigners();

            controllerAddr = returnController(controller);
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

module.exports = { doSingleStakeTest };