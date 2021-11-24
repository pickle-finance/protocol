/** NOTES ABOUT THIS TEST FILE
-- Only designed for testing against LPs

 * **/

var chai = require("chai");
chai.use(require('chai-roughly'));
const { expect } = require('chai');
const { ethers, network, deployments } = require('hardhat');
const { increaseTime, overwriteTokenAmount, increaseBlock, returnSigner, fastForwardAWeek, findSlot, returnController } = require("./utils/helpers");
const { BigNumber } = require("@ethersproject/bignumber");
const { setupSigners, snowballAddr, treasuryAddr, MAX_UINT256 } = require("./utils/static");
const GaugeProxyAddr = "0x215D5eDEb6A6a3f84AE9d72962FEaCCdF815BF27";
const gaugeABI = [{ "type": "constructor", "stateMutability": "nonpayable", "inputs": [{ "type": "address", "name": "_token", "internalType": "address" }, { "type": "address", "name": "_governance", "internalType": "address" }] }, { "type": "event", "name": "RewardAdded", "inputs": [{ "type": "uint256", "name": "reward", "internalType": "uint256", "indexed": false }], "anonymous": false }, { "type": "event", "name": "RewardPaid", "inputs": [{ "type": "address", "name": "user", "internalType": "address", "indexed": true }, { "type": "uint256", "name": "reward", "internalType": "uint256", "indexed": false }], "anonymous": false }, { "type": "event", "name": "Staked", "inputs": [{ "type": "address", "name": "user", "internalType": "address", "indexed": true }, { "type": "uint256", "name": "amount", "internalType": "uint256", "indexed": false }], "anonymous": false }, { "type": "event", "name": "Withdrawn", "inputs": [{ "type": "address", "name": "user", "internalType": "address", "indexed": true }, { "type": "uint256", "name": "amount", "internalType": "uint256", "indexed": false }], "anonymous": false }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "address", "name": "", "internalType": "address" }], "name": "DISTRIBUTION", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "DURATION", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "address", "name": "", "internalType": "contract IERC20" }], "name": "SNOWBALL", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "address", "name": "", "internalType": "contract IERC20" }], "name": "SNOWCONE", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "address", "name": "", "internalType": "contract IERC20" }], "name": "TOKEN", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "address", "name": "", "internalType": "address" }], "name": "TREASURY", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "acceptGovernance", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "balanceOf", "inputs": [{ "type": "address", "name": "account", "internalType": "address" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "changeDistribution", "inputs": [{ "type": "address", "name": "_distribution", "internalType": "address" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "deposit", "inputs": [{ "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "depositAll", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "depositFor", "inputs": [{ "type": "uint256", "name": "amount", "internalType": "uint256" }, { "type": "address", "name": "account", "internalType": "address" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "derivedBalance", "inputs": [{ "type": "address", "name": "account", "internalType": "address" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "derivedBalances", "inputs": [{ "type": "address", "name": "", "internalType": "address" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "derivedSupply", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "earned", "inputs": [{ "type": "address", "name": "account", "internalType": "address" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "exit", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "getReward", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "getRewardForDuration", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "address", "name": "", "internalType": "address" }], "name": "governance", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "kick", "inputs": [{ "type": "address", "name": "account", "internalType": "address" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "lastTimeRewardApplicable", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "lastUpdateTime", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "notifyRewardAmount", "inputs": [{ "type": "uint256", "name": "reward", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "address", "name": "", "internalType": "address" }], "name": "pendingGovernance", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "periodFinish", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "rewardPerToken", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "rewardPerTokenStored", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "rewardRate", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "rewards", "inputs": [{ "type": "address", "name": "", "internalType": "address" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "setGovernance", "inputs": [{ "type": "address", "name": "_governance", "internalType": "address" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "totalSupply", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "userRewardPerTokenPaid", "inputs": [{ "type": "address", "name": "", "internalType": "address" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "withdraw", "inputs": [{ "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "withdrawAll", "inputs": [] }];
const txnAmt = "35000000000000000000000";
const WAVAX = "0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7";

const doZapperTests = (
    Name,
    SnowGlobeAddr,
    PoolType,
    GaugeAddr = "",
    controller = "main",
    PoolTokenABI = [{ "type": "event", "name": "Approval", "inputs": [{ "type": "address", "name": "owner", "internalType": "address", "indexed": true }, { "type": "address", "name": "spender", "internalType": "address", "indexed": true }, { "type": "uint256", "name": "value", "internalType": "uint256", "indexed": false }], "anonymous": false }, { "type": "event", "name": "OwnershipTransferred", "inputs": [{ "type": "address", "name": "previousOwner", "internalType": "address", "indexed": true }, { "type": "address", "name": "newOwner", "internalType": "address", "indexed": true }], "anonymous": false }, { "type": "event", "name": "Transfer", "inputs": [{ "type": "address", "name": "from", "internalType": "address", "indexed": true }, { "type": "address", "name": "to", "internalType": "address", "indexed": true }, { "type": "uint256", "name": "value", "internalType": "uint256", "indexed": false }], "anonymous": false }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "allowance", "inputs": [{ "type": "address", "name": "owner", "internalType": "address" }, { "type": "address", "name": "spender", "internalType": "address" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "approve", "inputs": [{ "type": "address", "name": "spender", "internalType": "address" }, { "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "balanceOf", "inputs": [{ "type": "address", "name": "account", "internalType": "address" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "burn", "inputs": [{ "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "burnFrom", "inputs": [{ "type": "address", "name": "account", "internalType": "address" }, { "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint8", "name": "", "internalType": "uint8" }], "name": "decimals", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "decreaseAllowance", "inputs": [{ "type": "address", "name": "spender", "internalType": "address" }, { "type": "uint256", "name": "subtractedValue", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "increaseAllowance", "inputs": [{ "type": "address", "name": "spender", "internalType": "address" }, { "type": "uint256", "name": "addedValue", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "initialize", "inputs": [{ "type": "string", "name": "name", "internalType": "string" }, { "type": "string", "name": "symbol", "internalType": "string" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "mint", "inputs": [{ "type": "address", "name": "recipient", "internalType": "address" }, { "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "string", "name": "", "internalType": "string" }], "name": "name", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "address", "name": "", "internalType": "address" }], "name": "owner", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "renounceOwnership", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "string", "name": "", "internalType": "string" }], "name": "symbol", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "totalSupply", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "transfer", "inputs": [{ "type": "address", "name": "recipient", "internalType": "address" }, { "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "transferFrom", "inputs": [{ "type": "address", "name": "sender", "internalType": "address" }, { "type": "address", "name": "recipient", "internalType": "address" }, { "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "transferOwnership", "inputs": [{ "type": "address", "name": "newOwner", "internalType": "address" }] }],
    GlobeABI = [{ "type": "constructor", "stateMutability": "nonpayable", "inputs": [{ "type": "address", "name": "_token", "internalType": "address" }, { "type": "address", "name": "_governance", "internalType": "address" }, { "type": "address", "name": "_timelock", "internalType": "address" }, { "type": "address", "name": "_controller", "internalType": "address" }] }, { "type": "event", "name": "Approval", "inputs": [{ "type": "address", "name": "owner", "internalType": "address", "indexed": true }, { "type": "address", "name": "spender", "internalType": "address", "indexed": true }, { "type": "uint256", "name": "value", "internalType": "uint256", "indexed": false }], "anonymous": false }, { "type": "event", "name": "Transfer", "inputs": [{ "type": "address", "name": "from", "internalType": "address", "indexed": true }, { "type": "address", "name": "to", "internalType": "address", "indexed": true }, { "type": "uint256", "name": "value", "internalType": "uint256", "indexed": false }], "anonymous": false }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "allowance", "inputs": [{ "type": "address", "name": "owner", "internalType": "address" }, { "type": "address", "name": "spender", "internalType": "address" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "approve", "inputs": [{ "type": "address", "name": "spender", "internalType": "address" }, { "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "available", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "balance", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "balanceOf", "inputs": [{ "type": "address", "name": "account", "internalType": "address" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "address", "name": "", "internalType": "address" }], "name": "controller", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint8", "name": "", "internalType": "uint8" }], "name": "decimals", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "decreaseAllowance", "inputs": [{ "type": "address", "name": "spender", "internalType": "address" }, { "type": "uint256", "name": "subtractedValue", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "deposit", "inputs": [{ "type": "uint256", "name": "_amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "depositAll", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "earn", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "getRatio", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "address", "name": "", "internalType": "address" }], "name": "governance", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "harvest", "inputs": [{ "type": "address", "name": "reserve", "internalType": "address" }, { "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "increaseAllowance", "inputs": [{ "type": "address", "name": "spender", "internalType": "address" }, { "type": "uint256", "name": "addedValue", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "max", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "min", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "string", "name": "", "internalType": "string" }], "name": "name", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "setController", "inputs": [{ "type": "address", "name": "_controller", "internalType": "address" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "setGovernance", "inputs": [{ "type": "address", "name": "_governance", "internalType": "address" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "setMin", "inputs": [{ "type": "uint256", "name": "_min", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "setTimelock", "inputs": [{ "type": "address", "name": "_timelock", "internalType": "address" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "string", "name": "", "internalType": "string" }], "name": "symbol", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "address", "name": "", "internalType": "address" }], "name": "timelock", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "address", "name": "", "internalType": "contract IERC20" }], "name": "token", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "totalSupply", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "transfer", "inputs": [{ "type": "address", "name": "recipient", "internalType": "address" }, { "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "transferFrom", "inputs": [{ "type": "address", "name": "sender", "internalType": "address" }, { "type": "address", "name": "recipient", "internalType": "address" }, { "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "withdraw", "inputs": [{ "type": "uint256", "name": "_shares", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "withdrawAll", "inputs": [] }],
) => {

    describe(`${Name} Zapper Integration Tests`, () => {
        let snapshotId;
        let walletSigner;
        let LPToken, TokenA, TokenB, gaugeContract;
        const walletAddr = process.env.WALLET_ADDR;

        //These reset the state after each test is executed 
        beforeEach(async () => {
            snapshotId = await ethers.provider.send('evm_snapshot');
        })

        afterEach(async () => {
            await ethers.provider.send('evm_revert', [snapshotId]);
        })

        before(async () => {
            // Setup Signers
            walletSigner = await returnSigner(walletAddr);
            [timelockSigner, strategistSigner, governanceSigner] = await setupSigners();
            controllerAddr = returnController(controller);
            controllerSigner = await returnSigner(controllerAddr);

            // Deploy Snowglobe Contract
            const snowglobeName = `SnowGlobe${Name}`;
            if (SnowGlobeAddr == "") {
                const globeFactory = await ethers.getContractFactory(snowglobeName);
                globeContract = await globeFactory.deploy(assetAddr, governanceSigner._address, timelockSigner._address, controllerAddr);
                await controllerContract.setGlobe(assetAddr, globeContract.address);
                SnowGlobeAddr = globeContract.address;
            }
            else {
                globeContract = await ethers.getContractAt(GlobeABI, SnowGlobeAddr, governanceSigner);
            }

            // Derive Relevant Tokens
            let lpTokenAddr = await globeContract.token();
            LPToken = await ethers.getContractAt(getPoolABI(PoolType), lpTokenAddr, walletSigner);
            let slot = getLpSlot(PoolType);
            await overwriteTokenAmount(lpTokenAddr, walletAddr, txnAmt, slot);

            let tokenAAddr = await LPToken.token0();
            TokenA = await ethers.getContractAt("contracts/lib/erc20.sol:IERC20", tokenAAddr, walletSigner);
            let slotA = findSlot(tokenAAddr);
            await overwriteTokenAmount(tokenAAddr, walletAddr, txnAmt, slotA);

            let tokenBAddr = await LPToken.token1();
            TokenB = await ethers.getContractAt("contracts/lib/erc20.sol:IERC20", tokenBAddr, walletSigner);
            let slotB = findSlot(tokenBAddr);
            await overwriteTokenAmount(tokenBAddr, walletAddr, txnAmt, slotB);

            // Load GaugeProxy V2
            let gaugeProxyContract = await ethers.getContractAt("IGaugeProxyV2", GaugeProxyAddr, walletSigner);


            // Deploy Gauge
            if (GaugeAddr == "") {
                //TODO ADD Setup new gauge with GaugeProxy
                const gaugeFactory = await ethers.getContractFactory("GaugeV2");
                gaugeContract = await gaugeFactory.deploy(lpTokenAddr, governanceSigner._address);
                GaugeAddr = gaugeContract.address;
            }
            else {
                gaugeContract = await ethers.getContractAt(gaugeABI, GaugeAddr, governanceSigner);
            }

            // Deploy Zapper
            let contractType = getContractName(PoolType);
            const zapperFactory = await ethers.getContractFactory(contractType);
            zapperContract = await zapperFactory.deploy();
            zapperAddr = zapperContract.address;

            //Approvals
            await TokenA.approve(zapperAddr, MAX_UINT256);
            await TokenB.approve(zapperAddr, MAX_UINT256);
            await globeContract.connect(walletSigner).approve(zapperAddr, MAX_UINT256);
            await globeContract.connect(walletSigner).approve(GaugeAddr, MAX_UINT256);


        });
        describe("When setup is completed..", async () => {
            it("..contracts are loaded", async () => {
                expect(SnowGlobeAddr).to.not.be.empty;
                expect(zapperAddr).to.not.be.empty;
                expect(GaugeAddr).to.not.be.empty;
                expect(LPToken.address).to.not.be.empty;
                expect(TokenA.address).to.not.be.empty;
                expect(TokenB.address).to.not.be.empty;
                console.log(`\tToken Addresses are ${TokenA.address} and ${TokenB.address}`);
            })

            it("..user has positive balances for tokens and LP", async () => {
                let lpBal = ethers.utils.formatEther(await LPToken.balanceOf(walletAddr));
                let aBal = ethers.utils.formatEther(await TokenA.balanceOf(walletAddr));
                let bBal = ethers.utils.formatEther(await TokenB.balanceOf(walletAddr));
                expect(Number(lpBal), "LP Balance empty").to.be.greaterThan(0);
                expect(Number(aBal), "TokenA Balance empty").to.be.greaterThan(0);
                expect(Number(bBal), "TokenB Balance empty").to.be.greaterThan(0);

            })
        })

        describe("When depositing..", async () => {
            it("..can zap in with TokenA", async () => {
                const txnAmt = "33";
                const amt = ethers.utils.parseEther(txnAmt);
                let [user1, globe1] = await getBalances(TokenA, LPToken, walletAddr, globeContract);
                let symbol = await TokenA.symbol;

                console.log(`The value of A before doing anything is: ${user1}`); 

                await zapperContract.zapIn(SnowGlobeAddr, 0, TokenA.address, amt);
                let [user2, globe2] = await getBalances(TokenA, LPToken, walletAddr, globeContract);
                printBals(`Zap ${txnAmt}`, globe2, user2);

                console.log(`The value of token A after zapping in is: ${user2}`); 
                console.log(`the difference between both A's : ${user1-user2}`);

                await globeContract.connect(walletSigner).earn();
                let [user3, globe3] = await getBalances(TokenA, LPToken, walletAddr, globeContract);
                printBals("Call earn()", globe3, user3);

                expect((user1 - user2) / Number(txnAmt)).to.be.greaterThan(0.98);
                expect(globe2).to.be.greaterThan(globe1);
                expect(globe2).to.be.greaterThan(globe3);
            })

            it("..can zap in with TokenB", async () => {
                const txnAmt = "66";
                const amt = ethers.utils.parseEther(txnAmt);
                let [user1, globe1] = await getBalances(TokenB, LPToken, walletAddr, globeContract);
                printBals("Original", globe1, user1);

                console.log(`The value of B before doing anything is: ${user1}`); 

                await zapperContract.zapIn(SnowGlobeAddr, 0, TokenB.address, amt);
                let [user2, globe2] = await getBalances(TokenB, LPToken, walletAddr, globeContract);
                printBals(`Zap ${txnAmt}`, globe2, user2);

                console.log(`The value of token B after zapping in is: ${user2}`); 
                console.log(`the difference between both B's : ${user1-user2}`);

                await globeContract.connect(walletSigner).earn();
                let [user3, globe3] = await getBalances(TokenB, LPToken, walletAddr, globeContract);
                printBals("Call earn()", globe3, user3);

                expect((user1 - user2) / Number(txnAmt)).to.be.greaterThan(0.98);
                expect(globe2).to.be.greaterThan(globe1);
                expect(globe2).to.be.greaterThan(globe3);
            })

            it("..can zap in with AVAX", async () => {
                const txnAmt = "55";
                const amt = ethers.utils.parseEther(txnAmt);
                let [user1, globe1] = await getBalancesAvax(LPToken, walletSigner, globeContract);
                printBals("Original", globe1, user1);

                console.log(`The value of A before zapping in with AVAX is: ${user1}`);

                await zapperContract.zapInAVAX(SnowGlobeAddr, 0, TokenB.address, { value: amt });
                let [user2, globe2] = await getBalancesAvax(LPToken, walletSigner, globeContract);
                printBals(`Zap ${txnAmt} AVAX`, globe2, user2);

                console.log(`The value of token A after zapping in with Avax is: ${user2}`); 
                console.log(`the difference between both A's : ${user1-user2}`);

                await globeContract.connect(walletSigner).earn();
                let [user3, globe3] = await getBalancesAvax(LPToken, walletSigner, globeContract);
                printBals("Call earn()", globe3, user3);

                expect((user1 - user2) / Number(txnAmt)).to.be.greaterThan(0.98);
                expect(globe2).to.be.greaterThan(globe1);
                expect(globe2).to.be.greaterThan(globe3);
            })
        })

        describe("When withdrawing..", async () => {
            it("..can zap out into TokenA", async () => {
                const txnAmt = "24";
                const amt = ethers.utils.parseEther(txnAmt);

                console.log(`The amount we are zapping in with is: ${amt}`);
                //let receipt = await gaugeContract.balanceOf(walletAddr);
                let balA = (TokenA.address != WAVAX) ? await returnBal(TokenA, walletAddr) : await returnWalletBal(walletAddr);

                console.log(`The balance of A before anything is done to it: ${balA}`);


                await zapperContract.zapIn(SnowGlobeAddr, 0, TokenA.address, amt);
                let receipt = await gaugeContract.balanceOf(walletAddr);
                let balABefore = (TokenA.address != WAVAX) ? await returnBal(TokenA, walletAddr) : await returnWalletBal(walletAddr);

                console.log(`The balance of A before we zap out is: ${balABefore}`);

                await globeContract.connect(walletSigner).earn();
                await gaugeContract.connect(walletSigner).withdrawAll();
                await zapperContract.zapOutAndSwap(SnowGlobeAddr, receipt, TokenA.address, 0);

                let balAAfter = (TokenA.address != WAVAX) ? await returnBal(TokenA, walletAddr) : await returnWalletBal(walletAddr);
                let receipt2 = await gaugeContract.balanceOf(walletAddr);

                console.log(`The balance of A after we zap out is: ${balAAfter}`);
                console.log(`The difference of A before and after is: ${balAAfter-balABefore}`);


                expect(receipt2).to.be.equals(0);
                (TokenA.address != WAVAX) ?
                    expect(balAAfter - balABefore).to.roughly(0.01).deep.equal(Number(txnAmt)) :
                    expect(balAAfter).to.be.greaterThan(balABefore);
            })

            it("..can zap out into TokenB", async () => {
                const txnAmt = "35";
                const amt = ethers.utils.parseEther(txnAmt);

                console.log(`The amount we are zapping in with is: ${amt}`);
                let balB = (TokenB.address != WAVAX) ? await returnBal(TokenB, walletAddr) : await returnWalletBal(walletAddr);
                console.log(`The balance of B before we do anything is: ${balB}`);

                await zapperContract.zapIn(SnowGlobeAddr, 0, TokenB.address, amt);
                let receipt = await gaugeContract.balanceOf(walletAddr);
                let balBBefore = (TokenB.address != WAVAX) ? await returnBal(TokenB, walletAddr) : await returnWalletBal(walletAddr);

                console.log(`The balance of B before we zap out is: ${balBBefore}`);
               

                await globeContract.connect(walletSigner).earn();
                await gaugeContract.connect(walletSigner).withdrawAll();
                await zapperContract.zapOutAndSwap(SnowGlobeAddr, receipt, TokenB.address, 0);

                let balBAfter = (TokenB.address != WAVAX) ? await returnBal(TokenB, walletAddr) : await returnWalletBal(walletAddr);
                let receipt2 = await gaugeContract.balanceOf(walletAddr);

                console.log(`The balance of B after we zap out is: ${balBAfter}`);
                console.log(`The difference of B before and after is: ${balBAfter-balBBefore}`);



                expect(receipt2).to.be.equals(0);
                (TokenB.address != WAVAX) ?
                    expect(balBAfter - balBBefore).to.roughly(0.01).deep.equal(Number(txnAmt)) :
                    expect(balBAfter).to.be.greaterThan(balBBefore);
            })

            it("..can zap out equally", async () => {
                const txnAmt = "45";
                const amt = ethers.utils.parseEther(txnAmt);

                console.log(`The amount we are zapping in with is: ${amt}`);
                let balA = (TokenA.address != WAVAX) ? await returnBal(TokenA, walletAddr) : await returnWalletBal(walletAddr);
                let balB = (TokenB.address != WAVAX) ? await returnBal(TokenB, walletAddr) : await returnWalletBal(walletAddr);
                console.log(`The balance of A and B before we do anything is ${balA} and ${balB}`);

                await zapperContract.zapIn(SnowGlobeAddr, 0, TokenA.address, amt);
                let receipt = await gaugeContract.balanceOf(walletAddr);
                let balABefore = (TokenA.address != WAVAX) ? await returnBal(TokenA, walletAddr) : await returnWalletBal(walletAddr);
                let balBBefore = (TokenB.address != WAVAX) ? await returnBal(TokenB, walletAddr) : await returnWalletBal(walletAddr);

                console.log(`The balance of A before we zap out is: ${balABefore}`);
                console.log(`The balance of B before we zap out is: ${balBBefore}`);

                await globeContract.connect(walletSigner).earn();
                await gaugeContract.connect(walletSigner).withdrawAll();
                await zapperContract.zapOut(SnowGlobeAddr, receipt);
                let receipt2 = await gaugeContract.balanceOf(walletAddr);
                let balAAfter = (TokenA.address != WAVAX) ? await returnBal(TokenA, walletAddr) : await returnWalletBal(walletAddr);
                let balBAfter = (TokenB.address != WAVAX) ? await returnBal(TokenB, walletAddr) : await returnWalletBal(walletAddr);


                console.log(`The balance of A after we zap out is: ${balAAfter}`);
                console.log(`The balance of B after we zap out is: ${balBAfter}`);



                console.log(`The difference of A before and after is: ${balAAfter-balABefore}`);
                console.log(`The difference of B before and after is: ${balBAfter-balBBefore}`);

                
                console.log(`The thing we want our balance to be equal to is: ${Number(txnAmt) / 2}`);
                
                (TokenA.address != WAVAX) ?
                    expect(balAAfter - balABefore,"Incorrect TokenA").to.roughly(0.01).deep.equal(Number(txnAmt) / 2) :
                    expect(balAAfter).to.be.greaterThan(balABefore);
                (TokenB.address != WAVAX) ?
                    expect(balBAfter - balBBefore,"Incorrect TokenB").to.roughly(0.01).deep.equal(Number(txnAmt) / 2) :
                    expect(balBAfter).to.be.greaterThan(balBBefore);
                expect(receipt2).to.be.equals(0);
            })
        })

        describe("When minimum amounts unmet..", async () => {
            it("..reverts on zap in token", async () => {
                const txnAmt = "100";
                const amt = ethers.utils.parseEther(txnAmt);
               
                await expect(zapperContract.zapIn(SnowGlobeAddr, amt, TokenA.address, amt)).to.be.reverted;
            })
            it("..reverts on zap in avax", async () => {
                const txnAmt = "1";
                const txnAmt2 = "5";
                const amt = ethers.utils.parseEther(txnAmt);
                const amt2 = ethers.utils.parseEther(txnAmt2);
                
                //amt was too large that it succeeds when reaching line 60 of the zapper contract. However, we want it to fail
                console.log(`the token A address is ${tokenA.address}`);
                console.log(`the token B address is ${tokenB.address}`);

                
                await expect(zapperContract.zapInAVAX(SnowGlobeAddr, amt2, TokenA.address, { value: txnAmt })).to.be.reverted;
            })

            it("..reverts on zap out token", async () => {
                const txnAmt = "35";
                const amt = ethers.utils.parseEther(txnAmt);
                
                await zapperContract.zapIn(SnowGlobeAddr, 0, TokenB.address, amt);
                let receipt = await gaugeContract.balanceOf(walletAddr);
                await globeContract.connect(walletSigner).earn();
                await gaugeContract.connect(walletSigner).withdrawAll();
                await expect(zapperContract.zapOutAndSwap(SnowGlobeAddr, receipt, TokenB.address, amt)).to.be.reverted;
            })

            //missing
            it("..reverts on zap out avax", async () => {
            })
        })

    })

    async function returnWalletBal(_wall) {
        return Number(ethers.utils.formatEther(await ethers.provider.getBalance(_wall)))
    }

    async function returnBal(_contract, _addr) {
        return Number(ethers.utils.formatEther(await _contract.balanceOf(_addr)))
    }

    function printBals(context, globe, user) {
        let numGlobe = Number(globe).toFixed(2);
        let numUser = Number(user).toFixed(2);

        console.log(`\t${context} -  Globe: ${numGlobe} LP , User: ${numUser} Token`);
    }

    async function getBalances(_token, _lp, walletAddr, globeContract) {
        const user = Number(ethers.utils.formatEther(await _token.balanceOf(walletAddr)));
        const globe = Number(ethers.utils.formatEther(await _lp.balanceOf(globeContract.address)));

        return [user, globe]
    }

    async function getBalancesAvax(_lp, walletSigner, globeContract) {
        const user = Number(ethers.utils.formatEther(await walletSigner.getBalance()));
        const globe = Number(ethers.utils.formatEther(await _lp.balanceOf(globeContract.address)));

        return [user, globe]
    }

    function getContractName(_poolType) {
        let contractName = "";

        // Purposefully verbose PoolType names so not to confuse with tokens symbols
        switch (_poolType) {
            case "Pangolin": contractName = "SnowglobeZapAvaxPangolin"; break;
            case "TraderJoe": contractName = "SnowglobeZapAvaxTraderJoe"; break;
            default: contractName = "POOL TYPE UNDEFINED";
        }
        return contractName
    }

    function getPoolABI(_poolType) {
        let abi = "";

        switch (_poolType) {
            case "Pangolin": abi = [{ "type": "constructor", "stateMutability": "nonpayable", "payable": false, "inputs": [] }, { "type": "event", "name": "Approval", "inputs": [{ "type": "address", "name": "owner", "internalType": "address", "indexed": true }, { "type": "address", "name": "spender", "internalType": "address", "indexed": true }, { "type": "uint256", "name": "value", "internalType": "uint256", "indexed": false }], "anonymous": false }, { "type": "event", "name": "Burn", "inputs": [{ "type": "address", "name": "sender", "internalType": "address", "indexed": true }, { "type": "uint256", "name": "amount0", "internalType": "uint256", "indexed": false }, { "type": "uint256", "name": "amount1", "internalType": "uint256", "indexed": false }, { "type": "address", "name": "to", "internalType": "address", "indexed": true }], "anonymous": false }, { "type": "event", "name": "Mint", "inputs": [{ "type": "address", "name": "sender", "internalType": "address", "indexed": true }, { "type": "uint256", "name": "amount0", "internalType": "uint256", "indexed": false }, { "type": "uint256", "name": "amount1", "internalType": "uint256", "indexed": false }], "anonymous": false }, { "type": "event", "name": "Swap", "inputs": [{ "type": "address", "name": "sender", "internalType": "address", "indexed": true }, { "type": "uint256", "name": "amount0In", "internalType": "uint256", "indexed": false }, { "type": "uint256", "name": "amount1In", "internalType": "uint256", "indexed": false }, { "type": "uint256", "name": "amount0Out", "internalType": "uint256", "indexed": false }, { "type": "uint256", "name": "amount1Out", "internalType": "uint256", "indexed": false }, { "type": "address", "name": "to", "internalType": "address", "indexed": true }], "anonymous": false }, { "type": "event", "name": "Sync", "inputs": [{ "type": "uint112", "name": "reserve0", "internalType": "uint112", "indexed": false }, { "type": "uint112", "name": "reserve1", "internalType": "uint112", "indexed": false }], "anonymous": false }, { "type": "event", "name": "Transfer", "inputs": [{ "type": "address", "name": "from", "internalType": "address", "indexed": true }, { "type": "address", "name": "to", "internalType": "address", "indexed": true }, { "type": "uint256", "name": "value", "internalType": "uint256", "indexed": false }], "anonymous": false }, { "type": "function", "stateMutability": "view", "payable": false, "outputs": [{ "type": "bytes32", "name": "", "internalType": "bytes32" }], "name": "DOMAIN_SEPARATOR", "inputs": [], "constant": true }, { "type": "function", "stateMutability": "view", "payable": false, "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "MINIMUM_LIQUIDITY", "inputs": [], "constant": true }, { "type": "function", "stateMutability": "view", "payable": false, "outputs": [{ "type": "bytes32", "name": "", "internalType": "bytes32" }], "name": "PERMIT_TYPEHASH", "inputs": [], "constant": true }, { "type": "function", "stateMutability": "view", "payable": false, "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "allowance", "inputs": [{ "type": "address", "name": "", "internalType": "address" }, { "type": "address", "name": "", "internalType": "address" }], "constant": true }, { "type": "function", "stateMutability": "nonpayable", "payable": false, "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "approve", "inputs": [{ "type": "address", "name": "spender", "internalType": "address" }, { "type": "uint256", "name": "value", "internalType": "uint256" }], "constant": false }, { "type": "function", "stateMutability": "view", "payable": false, "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "balanceOf", "inputs": [{ "type": "address", "name": "", "internalType": "address" }], "constant": true }, { "type": "function", "stateMutability": "nonpayable", "payable": false, "outputs": [{ "type": "uint256", "name": "amount0", "internalType": "uint256" }, { "type": "uint256", "name": "amount1", "internalType": "uint256" }], "name": "burn", "inputs": [{ "type": "address", "name": "to", "internalType": "address" }], "constant": false }, { "type": "function", "stateMutability": "view", "payable": false, "outputs": [{ "type": "uint8", "name": "", "internalType": "uint8" }], "name": "decimals", "inputs": [], "constant": true }, { "type": "function", "stateMutability": "view", "payable": false, "outputs": [{ "type": "address", "name": "", "internalType": "address" }], "name": "factory", "inputs": [], "constant": true }, { "type": "function", "stateMutability": "view", "payable": false, "outputs": [{ "type": "uint112", "name": "_reserve0", "internalType": "uint112" }, { "type": "uint112", "name": "_reserve1", "internalType": "uint112" }, { "type": "uint32", "name": "_blockTimestampLast", "internalType": "uint32" }], "name": "getReserves", "inputs": [], "constant": true }, { "type": "function", "stateMutability": "nonpayable", "payable": false, "outputs": [], "name": "initialize", "inputs": [{ "type": "address", "name": "_token0", "internalType": "address" }, { "type": "address", "name": "_token1", "internalType": "address" }], "constant": false }, { "type": "function", "stateMutability": "view", "payable": false, "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "kLast", "inputs": [], "constant": true }, { "type": "function", "stateMutability": "nonpayable", "payable": false, "outputs": [{ "type": "uint256", "name": "liquidity", "internalType": "uint256" }], "name": "mint", "inputs": [{ "type": "address", "name": "to", "internalType": "address" }], "constant": false }, { "type": "function", "stateMutability": "view", "payable": false, "outputs": [{ "type": "string", "name": "", "internalType": "string" }], "name": "name", "inputs": [], "constant": true }, { "type": "function", "stateMutability": "view", "payable": false, "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "nonces", "inputs": [{ "type": "address", "name": "", "internalType": "address" }], "constant": true }, { "type": "function", "stateMutability": "nonpayable", "payable": false, "outputs": [], "name": "permit", "inputs": [{ "type": "address", "name": "owner", "internalType": "address" }, { "type": "address", "name": "spender", "internalType": "address" }, { "type": "uint256", "name": "value", "internalType": "uint256" }, { "type": "uint256", "name": "deadline", "internalType": "uint256" }, { "type": "uint8", "name": "v", "internalType": "uint8" }, { "type": "bytes32", "name": "r", "internalType": "bytes32" }, { "type": "bytes32", "name": "s", "internalType": "bytes32" }], "constant": false }, { "type": "function", "stateMutability": "view", "payable": false, "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "price0CumulativeLast", "inputs": [], "constant": true }, { "type": "function", "stateMutability": "view", "payable": false, "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "price1CumulativeLast", "inputs": [], "constant": true }, { "type": "function", "stateMutability": "nonpayable", "payable": false, "outputs": [], "name": "skim", "inputs": [{ "type": "address", "name": "to", "internalType": "address" }], "constant": false }, { "type": "function", "stateMutability": "nonpayable", "payable": false, "outputs": [], "name": "swap", "inputs": [{ "type": "uint256", "name": "amount0Out", "internalType": "uint256" }, { "type": "uint256", "name": "amount1Out", "internalType": "uint256" }, { "type": "address", "name": "to", "internalType": "address" }, { "type": "bytes", "name": "data", "internalType": "bytes" }], "constant": false }, { "type": "function", "stateMutability": "view", "payable": false, "outputs": [{ "type": "string", "name": "", "internalType": "string" }], "name": "symbol", "inputs": [], "constant": true }, { "type": "function", "stateMutability": "nonpayable", "payable": false, "outputs": [], "name": "sync", "inputs": [], "constant": false }, { "type": "function", "stateMutability": "view", "payable": false, "outputs": [{ "type": "address", "name": "", "internalType": "address" }], "name": "token0", "inputs": [], "constant": true }, { "type": "function", "stateMutability": "view", "payable": false, "outputs": [{ "type": "address", "name": "", "internalType": "address" }], "name": "token1", "inputs": [], "constant": true }, { "type": "function", "stateMutability": "view", "payable": false, "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "totalSupply", "inputs": [], "constant": true }, { "type": "function", "stateMutability": "nonpayable", "payable": false, "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "transfer", "inputs": [{ "type": "address", "name": "to", "internalType": "address" }, { "type": "uint256", "name": "value", "internalType": "uint256" }], "constant": false }, { "type": "function", "stateMutability": "nonpayable", "payable": false, "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "transferFrom", "inputs": [{ "type": "address", "name": "from", "internalType": "address" }, { "type": "address", "name": "to", "internalType": "address" }, { "type": "uint256", "name": "value", "internalType": "uint256" }], "constant": false }]; break;
            case "TraderJoe": abi = [{"type":"constructor","stateMutability":"nonpayable","inputs":[]},{"type":"event","name":"Approval","inputs":[{"type":"address","name":"owner","internalType":"address","indexed":true},{"type":"address","name":"spender","internalType":"address","indexed":true},{"type":"uint256","name":"value","internalType":"uint256","indexed":false}],"anonymous":false},{"type":"event","name":"Burn","inputs":[{"type":"address","name":"sender","internalType":"address","indexed":true},{"type":"uint256","name":"amount0","internalType":"uint256","indexed":false},{"type":"uint256","name":"amount1","internalType":"uint256","indexed":false},{"type":"address","name":"to","internalType":"address","indexed":true}],"anonymous":false},{"type":"event","name":"Mint","inputs":[{"type":"address","name":"sender","internalType":"address","indexed":true},{"type":"uint256","name":"amount0","internalType":"uint256","indexed":false},{"type":"uint256","name":"amount1","internalType":"uint256","indexed":false}],"anonymous":false},{"type":"event","name":"Swap","inputs":[{"type":"address","name":"sender","internalType":"address","indexed":true},{"type":"uint256","name":"amount0In","internalType":"uint256","indexed":false},{"type":"uint256","name":"amount1In","internalType":"uint256","indexed":false},{"type":"uint256","name":"amount0Out","internalType":"uint256","indexed":false},{"type":"uint256","name":"amount1Out","internalType":"uint256","indexed":false},{"type":"address","name":"to","internalType":"address","indexed":true}],"anonymous":false},{"type":"event","name":"Sync","inputs":[{"type":"uint112","name":"reserve0","internalType":"uint112","indexed":false},{"type":"uint112","name":"reserve1","internalType":"uint112","indexed":false}],"anonymous":false},{"type":"event","name":"Transfer","inputs":[{"type":"address","name":"from","internalType":"address","indexed":true},{"type":"address","name":"to","internalType":"address","indexed":true},{"type":"uint256","name":"value","internalType":"uint256","indexed":false}],"anonymous":false},{"type":"function","stateMutability":"view","outputs":[{"type":"bytes32","name":"","internalType":"bytes32"}],"name":"DOMAIN_SEPARATOR","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"MINIMUM_LIQUIDITY","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"bytes32","name":"","internalType":"bytes32"}],"name":"PERMIT_TYPEHASH","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"allowance","inputs":[{"type":"address","name":"","internalType":"address"},{"type":"address","name":"","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[{"type":"bool","name":"","internalType":"bool"}],"name":"approve","inputs":[{"type":"address","name":"spender","internalType":"address"},{"type":"uint256","name":"value","internalType":"uint256"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"balanceOf","inputs":[{"type":"address","name":"","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[{"type":"uint256","name":"amount0","internalType":"uint256"},{"type":"uint256","name":"amount1","internalType":"uint256"}],"name":"burn","inputs":[{"type":"address","name":"to","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint8","name":"","internalType":"uint8"}],"name":"decimals","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"factory","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint112","name":"_reserve0","internalType":"uint112"},{"type":"uint112","name":"_reserve1","internalType":"uint112"},{"type":"uint32","name":"_blockTimestampLast","internalType":"uint32"}],"name":"getReserves","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"initialize","inputs":[{"type":"address","name":"_token0","internalType":"address"},{"type":"address","name":"_token1","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"kLast","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[{"type":"uint256","name":"liquidity","internalType":"uint256"}],"name":"mint","inputs":[{"type":"address","name":"to","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"string","name":"","internalType":"string"}],"name":"name","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"nonces","inputs":[{"type":"address","name":"","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"permit","inputs":[{"type":"address","name":"owner","internalType":"address"},{"type":"address","name":"spender","internalType":"address"},{"type":"uint256","name":"value","internalType":"uint256"},{"type":"uint256","name":"deadline","internalType":"uint256"},{"type":"uint8","name":"v","internalType":"uint8"},{"type":"bytes32","name":"r","internalType":"bytes32"},{"type":"bytes32","name":"s","internalType":"bytes32"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"price0CumulativeLast","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"price1CumulativeLast","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"skim","inputs":[{"type":"address","name":"to","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"swap","inputs":[{"type":"uint256","name":"amount0Out","internalType":"uint256"},{"type":"uint256","name":"amount1Out","internalType":"uint256"},{"type":"address","name":"to","internalType":"address"},{"type":"bytes","name":"data","internalType":"bytes"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"string","name":"","internalType":"string"}],"name":"symbol","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"sync","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"token0","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"token1","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"totalSupply","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[{"type":"bool","name":"","internalType":"bool"}],"name":"transfer","inputs":[{"type":"address","name":"to","internalType":"address"},{"type":"uint256","name":"value","internalType":"uint256"}]},{"type":"function","stateMutability":"nonpayable","outputs":[{"type":"bool","name":"","internalType":"bool"}],"name":"transferFrom","inputs":[{"type":"address","name":"from","internalType":"address"},{"type":"address","name":"to","internalType":"address"},{"type":"uint256","name":"value","internalType":"uint256"}]}];break;
            default: abi = "POOL TYPE UNDEFINED";
        }
        return abi
    }

    function getLpSlot(_poolType) {
        let slot = "";
        switch (_poolType) {
            case "Pangolin": slot = "1"; break;
            case "TraderJoe": slot = "1"; break;
            default: slot = "POOL TYPE UNDEFINED";
        }
        return slot
    }


}



module.exports = { doZapperTests };