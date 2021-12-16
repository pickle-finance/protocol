/* eslint-disable no-undef */
const { ethers, network } = require("hardhat");
const chai = require("chai");
const { BigNumber } = require("@ethersproject/bignumber");
const { increaseTime, overwriteTokenAmount, increaseBlock, returnSigner, fastForwardAWeek } = require("./utils/helpers");
const { expect } = chai;
const { setupSigners, snowballAddr, treasuryAddr} = require("./utils/static");

const globeABI = [{ "type": "constructor", "stateMutability": "nonpayable", "inputs": [{ "type": "address", "name": "_token", "internalType": "address" }, { "type": "address", "name": "_governance", "internalType": "address" }, { "type": "address", "name": "_timelock", "internalType": "address" }, { "type": "address", "name": "_controller", "internalType": "address" }] }, { "type": "event", "name": "Approval", "inputs": [{ "type": "address", "name": "owner", "internalType": "address", "indexed": true }, { "type": "address", "name": "spender", "internalType": "address", "indexed": true }, { "type": "uint256", "name": "value", "internalType": "uint256", "indexed": false }], "anonymous": false }, { "type": "event", "name": "Transfer", "inputs": [{ "type": "address", "name": "from", "internalType": "address", "indexed": true }, { "type": "address", "name": "to", "internalType": "address", "indexed": true }, { "type": "uint256", "name": "value", "internalType": "uint256", "indexed": false }], "anonymous": false }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "allowance", "inputs": [{ "type": "address", "name": "owner", "internalType": "address" }, { "type": "address", "name": "spender", "internalType": "address" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "approve", "inputs": [{ "type": "address", "name": "spender", "internalType": "address" }, { "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "available", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "balance", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "balanceOf", "inputs": [{ "type": "address", "name": "account", "internalType": "address" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "address", "name": "", "internalType": "address" }], "name": "controller", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint8", "name": "", "internalType": "uint8" }], "name": "decimals", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "decreaseAllowance", "inputs": [{ "type": "address", "name": "spender", "internalType": "address" }, { "type": "uint256", "name": "subtractedValue", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "deposit", "inputs": [{ "type": "uint256", "name": "_amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "depositAll", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "earn", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "getRatio", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "address", "name": "", "internalType": "address" }], "name": "governance", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "harvest", "inputs": [{ "type": "address", "name": "reserve", "internalType": "address" }, { "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "increaseAllowance", "inputs": [{ "type": "address", "name": "spender", "internalType": "address" }, { "type": "uint256", "name": "addedValue", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "max", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "min", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "string", "name": "", "internalType": "string" }], "name": "name", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "setController", "inputs": [{ "type": "address", "name": "_controller", "internalType": "address" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "setGovernance", "inputs": [{ "type": "address", "name": "_governance", "internalType": "address" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "setMin", "inputs": [{ "type": "uint256", "name": "_min", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "setTimelock", "inputs": [{ "type": "address", "name": "_timelock", "internalType": "address" }] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "string", "name": "", "internalType": "string" }], "name": "symbol", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "address", "name": "", "internalType": "address" }], "name": "timelock", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "address", "name": "", "internalType": "contract IERC20" }], "name": "token", "inputs": [] }, { "type": "function", "stateMutability": "view", "outputs": [{ "type": "uint256", "name": "", "internalType": "uint256" }], "name": "totalSupply", "inputs": [] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "transfer", "inputs": [{ "type": "address", "name": "recipient", "internalType": "address" }, { "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [{ "type": "bool", "name": "", "internalType": "bool" }], "name": "transferFrom", "inputs": [{ "type": "address", "name": "sender", "internalType": "address" }, { "type": "address", "name": "recipient", "internalType": "address" }, { "type": "uint256", "name": "amount", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "withdraw", "inputs": [{ "type": "uint256", "name": "_shares", "internalType": "uint256" }] }, { "type": "function", "stateMutability": "nonpayable", "outputs": [], "name": "withdrawAll", "inputs": [] }];

const doFoldingStrategyTest = (
    name,
    snowglobeAddr,
    strategyAddr,
    stratABI,
    slot = "0",
    fold = true,
    controller = "main"
) => {

    const walletAddr = process.env.WALLET_ADDR;
    let assetContract, controllerContract;
    let governanceSigner, strategistSigner, timelockSigner;
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

            await network.provider.send('hardhat_impersonateAccount', [walletAddr]);
            console.log(`impersonating account: ${walletAddr}`);
            walletSigner = ethers.provider.getSigner(walletAddr);
            [timelockSigner, strategistSigner, governanceSigner] = await setupSigners();

            //Add a new case here when including a new family of folding strategies
            switch (controller) {
                case "main": controllerAddr = "0xf7B8D9f8a82a7a6dd448398aFC5c77744Bd6cb85";break;
                case "backup": controllerAddr = "0xACc69DEeF119AB5bBf14e6Aaf0536eAFB3D6e046"; break;
                case "aave": controllerAddr = "0x425A863762BBf24A986d8EaE2A367cb514591C6F"; break;
                case "bankerJoe": controllerAddr = "0xFb7102506B4815a24e3cE3eAA6B834BE7a5f2807"; break;
                case "benqi": controllerAddr = "0x8bfBA506B442f0D93Da2aDFd1ab70b7cB6a77B76"; break;
                default : break;
            }

            console.log(`using controller: ${controllerAddr}`);

            walletSigner = await returnSigner(walletAddr);
            controllerContract = await ethers.getContractAt("ControllerV4", controllerAddr, governanceSigner);
            timelockAddr = await controllerContract.timelock();
            timelockSigner = returnSigner(timelockAddr);

            //If strategy address not supplied then we should deploy and setup a new strategy
            if (!strategyAddr) {
                console.log(`deploying strategy ${strategyName}`);
                const stratFactory = await ethers.getContractFactory(strategyName);
                // Now we can deploy the new strategy
                console.log(`${governanceSigner._address}, ${strategistSigner._address}, ${controllerAddr}, ${timelockAddr}`);
                strategyContract = await stratFactory.connect(walletSigner).deploy(governanceSigner._address, strategistSigner._address, controllerAddr, timelockAddr);
                console.log(`deployed new strategy at ${strategyContract.address}`);
                assetAddr = await strategyContract.want();
                console.log(`asset address: ${assetAddr}`);
                strategyAddr = strategyContract.address;
                console.log(`1`);
                const approveStrategy = await controllerContract.connect(timelockSigner).approveStrategy(assetAddr,strategyAddr);
                console.log(`2`);
                const tx_approveStrategy = await approveStrategy.wait(1);
                console.log(`3`);
                if (!tx_approveStrategy.status) {
                    console.error("Error approving the strategy for: ",name);
                    return;
                }
                console.log("Approved Strategy in the Controller for: ",name);

                /* Handle old strategy */
                const oldStrategyAddr = await controllerContract.strategies(assetAddr);
                if (oldStrategyAddr != 0) {
                    const oldStrategy = new ethers.Contract(oldStrategyAddr, stratABI, governanceSigner);
                    const harvest = await oldStrategy.connect(governanceSigner).harvest();
                    const tx_harvest = await harvest.wait(1);
                    if (!tx_harvest.status) {
                        console.error("Error harvesting the old strategy for: ",name);
                        return;
                    }
                    console.log("Harvested the old strategy for: ",name);
                    if (fold) {
                        // Before we can setup new strategy we must deleverage from old one
                        const deleverage = await oldStrategy.connect(governanceSigner).deleverageToMin();
                        const tx_deleverage = await deleverage.wait(1);
                        if (!tx_deleverage.status) {
                            console.error("Error deleveraging the old strategy for: ",name);
                            return;
                        }
                        console.log("Deleveraged the old strategy for: ",name);
                    }
                }

                const setStrategy = await controllerContract.connect(timelockSigner).setStrategy(assetAddr,strategyAddr);
                const tx_setStrategy = await setStrategy.wait(1);
                if (!tx_setStrategy.status) {
                    console.error("Error setting the strategy for: ",name);
                    return;
                }
                console.log("Set Strategy in the Controller for: ",name);

                const whitelist = await strategyContract.connect(governanceSigner).whitelistHarvester(walletAddr);
                const tx_whitelist = await whitelist.wait(1);
                if (!tx_whitelist.status) {
                    console.error("Error whitelisting harvester for: ",name);
                    return;
                }
                console.log('whitelisted the harvester for: ',name);

                const keeper = await strategyContract.connect(governanceSigner).addKeeper(walletAddr);
                const tx_keeper = await keeper.wait(1);
                if (!tx_keeper.status) {
                    console.error("Error adding keeper for: ",name);
                    return;
                }
                console.log('added keeper for: ',name);
            } else {            
                strategyContract = new ethers.Contract(strategyAddr, stratABI, governanceSigner);
                let timelockAddr = await strategyContract.timelock();
                timelockSigner = await returnSigner(timelockAddr);
            }
            assetAddr = strategyContract.want();
            
            if (!snowglobeAddr) {
                snowglobeAddr = await controllerContract.globes(assetAddr);
                console.log("controllerAddr: ",controllerAddr);
                console.log("snowglobeAddr: ",snowglobeAddr);
                if (snowglobeAddr != 0) {
                    globeContract = new ethers.Contract(snowglobeAddr, globeABI, governanceSigner);
                }
                else {
                    const globeFactory = await ethers.getContractFactory(snowglobeName);
                    globeContract = await globeFactory.deploy(assetAddr, governanceSigner._address, timelockSigner._address, controllerAddr);
                    const setGlobe = await controllerContract.setGlobe(assetAddr, globeContract.address);
                    const tx_setGlobe = await setGlobe.wait(1);
                    if (!tx_setGlobe.status) {
                        console.error("Error setting the globe for: ",name);
                        return;
                    }
                    console.log("Set Globe in the Controller for: ",name);
                    snowglobeAddr = globeContract.address;
                }
            }
            else {
                globeContract = new ethers.Contract(snowglobeAddr, globeABI, governanceSigner);
            }
            const earn = await globeContract.earn();
            const tx_earn = await earn.wait(1);
            if (!tx_earn.status) {
                console.error("Error calling earn in the Snowglobe for: ",name);
                return;
            }
            console.log("Called earn in the Snowglobe for: ",name);

            if (fold) {
                // Now leverage to max
                const leverage = await Strategy.connect(governanceSigner).leverageToMax();
                const tx_leverage = await leverage.wait(1);
                if (!tx_leverage.status) {
                    console.error("Error leveraging the strategy for: ",name);
                    return;
                }
                console.log("Leveraged the strategy for: ",name);
            }

            /* Gauges */
            const gaugeproxy_ABI = [{"type":"constructor","stateMutability":"nonpayable","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"contract IceQueen"}],"name":"MASTER","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"contract IERC20"}],"name":"SNOWBALL","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"contract IERC20"}],"name":"SNOWCONE","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"contract IERC20"}],"name":"TOKEN","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"acceptGovernance","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"addGauge","inputs":[{"type":"address","name":"_token","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"collect","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"deposit","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"distribute","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"gauges","inputs":[{"type":"address","name":"","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"getGauge","inputs":[{"type":"address","name":"_token","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"governance","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"length","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"pendingGovernance","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"pid","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"poke","inputs":[{"type":"address","name":"_owner","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"reset","inputs":[]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setGovernance","inputs":[{"type":"address","name":"_governance","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"setPID","inputs":[{"type":"uint256","name":"_pid","internalType":"uint256"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address","name":"","internalType":"address"}],"name":"tokenVote","inputs":[{"type":"address","name":"","internalType":"address"},{"type":"uint256","name":"","internalType":"uint256"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"address[]","name":"","internalType":"address[]"}],"name":"tokens","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"totalWeight","inputs":[]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"usedWeights","inputs":[{"type":"address","name":"","internalType":"address"}]},{"type":"function","stateMutability":"nonpayable","outputs":[],"name":"vote","inputs":[{"type":"address[]","name":"_tokenVote","internalType":"address[]"},{"type":"uint256[]","name":"_weights","internalType":"uint256[]"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"votes","inputs":[{"type":"address","name":"","internalType":"address"},{"type":"address","name":"","internalType":"address"}]},{"type":"function","stateMutability":"view","outputs":[{"type":"uint256","name":"","internalType":"uint256"}],"name":"weights","inputs":[{"type":"address","name":"","internalType":"address"}]}];
            const gaugeproxy_addr = "0x215D5eDEb6A6a3f84AE9d72962FEaCCdF815BF27";

            const GaugeProxy = new ethers.Contract(gaugeproxy_addr, gaugeproxy_ABI, governanceSigner);
            const gauge = await GaugeProxy.getGauge(globeContract.address);
            if (gauge == 0) {
                const addGauge = await GaugeProxy.addGauge(globeContract.address);
                const tx_addGauge = await addGauge.wait(1);
                if (!tx_addGauge.status) {
                    console.error(`Error adding the gauge for: ${name}`);
                    return;
                }
                console.log(`addGauge for ${name}`);
            }

            assetContract = await ethers.getContractAt("ERC20", assetAddr, walletSigner);
            await overwriteTokenAmount(assetAddr, walletAddr, txnAmt, slot);
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

module.exports = { doFoldingStrategyTest };