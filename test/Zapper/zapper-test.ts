/** NOTES ABOUT THIS TEST FILE
-- Only designed for testing against LPs
***/
const { ethers } = require("hardhat");
import { BigNumber } from "@ethersproject/bignumber";

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
   returnSigner, fastForwardAWeek, findSlot, returnController 
} from "../utils/helpers";
import { 
   setupSigners, snowballAddr, 
   treasuryAddr, MAX_UINT256 
} from "../utils/static";
import { 
   Contract, 
   ContractFactory,
   Signer 
} from "ethers";

const GaugeProxyAddr = "0x215D5eDEb6A6a3f84AE9d72962FEaCCdF815BF27";
const gaugeABI = require('./abis/GaugeABI.json');
const txnAmt = "35000000000000000000000";
const WAVAX = "0xB31f66AA3C1e785363F0875A1B74E27b85FD66c7";

const poolTokenABI = require('./abis/PoolTokenABI.json');
const globeABI = require('./abis/Globe.json');

export function doZapperTests (
    Name: string,
    SnowGlobeAddr: string,
    PoolType: string,
    GaugeAddr = "",
    controller = "main",
    PoolTokenABI = poolTokenABI,
    GlobeABI = globeABI,
) {

    describe(`${Name} Zapper Integration Tests`, () => {
        let snapshotId: string;
        let assetAddr: string;
        let zapperAddr: string;
        let controllerAddr: string;
        let controllerSigner: Signer;
        let walletSigner: Signer;
        let LPToken: Contract;
        let TokenA: Contract;
        let TokenB: Contract;
        let gaugeContract: Contract;
        let globeContract: Contract;
        let controllerContract: Contract;
        let zapperContract: Contract;

        let timelockSigner: Signer
        let strategistSigner: Signer
        let governanceSigner: Signer

        const walletAddr = process.env.WALLET_ADDR === undefined ? '' : process.env.WALLET_ADDR;

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
                globeContract = await globeFactory.deploy(assetAddr, governanceSigner.getAddress(), timelockSigner.getAddress(), controllerAddr);
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
                gaugeContract = await gaugeFactory.deploy(lpTokenAddr, governanceSigner.getAddress());
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
               
                expect(zapperContract.zapIn(SnowGlobeAddr, amt, TokenA.address, amt)).to.be.reverted;
            })
            it("..reverts on zap in avax", async () => {
                const txnAmt = "1";
                const txnAmt2 = "5";
                const amt = ethers.utils.parseEther(txnAmt);
                const amt2 = ethers.utils.parseEther(txnAmt2);
                
                //amt was too large that it succeeds when reaching line 60 of the zapper contract. However, we want it to fail
                console.log(`the token A address is ${TokenA.address}`);
                console.log(`the token B address is ${TokenB.address}`);

                
                await expect(zapperContract.zapInAVAX(SnowGlobeAddr, amt2, TokenA.address, { value: txnAmt })).to.be.reverted;
;
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

    async function returnWalletBal(_wall: string) : Promise<number> {
        return Number(ethers.utils.formatEther(await ethers.provider.getBalance(_wall)))
    }

    async function returnBal(_contract: Contract, _addr: string) : Promise<number> {
        return Number(ethers.utils.formatEther(await _contract.balanceOf(_addr)))
    }

    function printBals(context: string, globe: number, user: number) {
        let numGlobe = Number(globe).toFixed(2);
        let numUser = Number(user).toFixed(2);

        console.log(`\t${context} -  Globe: ${numGlobe} LP , User: ${numUser} Token`);
    }

    async function getBalances(_token: Contract, _lp: Contract, walletAddr: string, globeContract: Contract) {
        const user = Number(ethers.utils.formatEther(await _token.balanceOf(walletAddr)));
        const globe = Number(ethers.utils.formatEther(await _lp.balanceOf(globeContract.address)));

        return [user, globe]
    }

    async function getBalancesAvax(_lp: Contract, walletSigner: Signer, globeContract: Contract) {
        const user = Number(ethers.utils.formatEther(await walletSigner.getBalance()));
        const globe = Number(ethers.utils.formatEther(await _lp.balanceOf(globeContract.address)));

        return [user, globe]
    }

    function getContractName(_poolType: string) : string {
        let contractName = "";

        // Purposefully verbose PoolType names so not to confuse with tokens symbols
        switch (_poolType) {
            case "Pangolin": contractName = "SnowglobeZapAvaxPangolin"; break;
            case "TraderJoe": contractName = "SnowglobeZapAvaxTraderJoe"; break;
            default: contractName = "POOL TYPE UNDEFINED";
        }
        return contractName
    }

    function getPoolABI(_poolType: string) : string {
        let abi = "";

        switch (_poolType) {
            case "Pangolin": abi = require('./abis/PangolinABI.json'); break;
            case "TraderJoe": abi = require('./abis/TraderJoeABI.json'); break;
            default: abi = "POOL TYPE UNDEFINED";
        }
        return abi
    }

    function getLpSlot(_poolType: string) : number{
        let slot
        switch (_poolType) {
            case "Pangolin": slot = 1; break;
            case "TraderJoe": slot = 1; break;
            default: slot = -1;
        }
        return slot
    }
}
