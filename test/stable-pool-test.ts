/** NOTES ABOUT THIS TEST FILE * - This is called by the test scripts file `all-stable-pools.js` * - It should work with n number of tokens in pool, but has only been tested against 4 * - It should be extended with any optional functionality that needs to be tested against a new pool * - If logic differs between pools, add variable to the input parameter with default off value, so we can choose which path each pool should take * * TODO:  - Support deploying new swap pools via this file * **/
import chai from "chai";
const { ethers, network } = require('hardhat');
const { expect } = require('chai');

import chaiAsPromised from 'chai-as-promised'
chai.use(chaiAsPromised)
import {
    Contract,
    Signer
} from "ethers";
import {
    increaseTime, overwriteTokenAmount, increaseBlock,
    returnSigner, fastForwardAWeek, findSlot
} from "./utils/helpers";
import {
    setupSigners,
    MAX_UINT256
} from "./utils/static";
import { log } from "./utils/log";

const txnAmt = "35000000000000000000000";

const IERC20 = require('./abis/IERC20.json');
const poolTokenABI = require('./abis/PoolTokenABI.json');
const poolABI = require('./abis/PoolABI.json');

export function doStablePoolTests(
    name: string,
    StableVaultAddr: string,
    tokenList: Array<string>,
    PoolTokenABI = poolTokenABI,
    PoolABI = poolABI
) {

    describe(`${name} StablePool Integration Tests`, () => {
        let snapshotId: string;
        let walletSigner: Signer;
        let deployer: Signer;
        let StablePool: Contract;
        let StablePoolToken: Contract;
        let StableVaultTokenAddr: string;
        let pooledTokens: Array<string>;
        let decimals: Array<number>;
        let lpTokenName: string;
        let lpTokenSymbol: string;
        let aValue: number;
        let fee: number;
        let adminFee: number;
        let lpTokenTargetAddress: string;
        let newPool: boolean = true;
        let tokenContracts: Array<Contract> = [];
        const walletAddr = process.env.WALLET_ADDR === undefined ? '' : process.env.WALLET_ADDR;

        //These reset the state after each test is executed 
        beforeEach(async () => {
            snapshotId = await ethers.provider.send('evm_snapshot');
        })

        afterEach(async () => {
            await ethers.provider.send('evm_revert', [snapshotId]);
        })

        before(async () => {
            walletSigner = await returnSigner(walletAddr);

            /**=======Get Token Contracts=======**/
            // -- When adding new sets of token pools, be sure to use slot20 to verify the slot the ERC20 employs
            // -- If slot is 0 then no changes required, if not be sure to add to the case/switch statement for helpers::findSlot()
            for (let item of tokenList) {
                process.stdout.write(`\tDeploying token contract: ${item}}`);
                let contract = await ethers.getContractAt(IERC20, item, walletSigner);
                process.stdout.write("..");
                tokenContracts.push(contract);
                process.stdout.write(`${await contract.symbol()} loaded\n`);
                let slot = findSlot(item);
                await overwriteTokenAmount(item, walletAddr, txnAmt, slot);

            }

            if (StableVaultAddr == "") {
                //TODO: Make this part of the IF statement work
                // Use this for testing new stablevaults
                /*
                const stablePoolFactory = await ethers.getContractFactory("SwapFlashLoan");
                StablePool = await stablePoolFactory.deploy();
                StableVaultAddr = StablePool.address;
        
                // Arrange init data
                pooledTokens = [testAToken.address, testBToken.address, testCToken.address, testDToken.address];
                decimals = [18, 18, 18, 6];
                lpTokenName = "Timbo Test Pool";
                lpTokenSymbol = "TIMPOOL";
                aValue = 60;
                fee = 3000000;
                adminFee = 1000000;
                lpTokenTargetAddress = "0x834ac088077db3fba31fde3829c77a46d038efc9";
        
                // Perform Init
                await StablePool.initialize(
                  pooledTokens,
                  decimals,
                  lpTokenName,
                  lpTokenSymbol,
                  aValue,
                  fee,
                  adminFee,
                  lpTokenTargetAddress,
                );
                */

            } else {
                // Load local instance of Stablevault contract from existing contract deployed on chain
                newPool = false;
                StablePool = await ethers.getContractAt(PoolABI, StableVaultAddr, deployer);
                let owner = await StablePool.owner();
                deployer = await returnSigner(owner);
                log(`\tDeployer Address is ${deployer.getAddress()}`)

                const response = await StablePool.swapStorage();
                StableVaultTokenAddr = response[6];
                log(`\tLP Token Address is : ${StableVaultTokenAddr}`);
                StablePoolToken = await ethers.getContractAt(PoolTokenABI, StableVaultTokenAddr, deployer);

            }
            log(`\tStablePool Address is : ${StablePool.address}`);

            let slot = findSlot(StableVaultTokenAddr);
            await overwriteTokenAmount(StableVaultTokenAddr, walletAddr, txnAmt, slot);
            await approveAll(tokenContracts, StableVaultAddr);
        });

        describe("Default Values", async () => {
            it("Pool is initialized correctly", async () => {
                //check owner
                const owner = await StablePool.owner();
                expect(owner, "Owner doesn't match deployer").to.equals(await deployer.getAddress());

                //check paused = false
                const paused = await StablePool.paused();
                expect(paused, "Pool is paused").to.be.false;

                if (newPool) {
                    //check A
                    const A = await StablePool.getA();
                    expect(parseInt(A), "A value doesn't match").to.equals(aValue);

                    // TODO: Check that each added token is present in pool
                    //forEach token in pool expect to be in token array

                }

            })
        })

        describe("When adding liquidity", async () => {
            it("the pool balance increases", async () => {
                const firstAsset: Contract = tokenContracts[0];
                const txnAmt = "2500";
                const amt = ethers.utils.parseEther(txnAmt);
                const preTokenAmt = ethers.utils.formatEther(await StablePool.getTokenBalance(0));
                const balsBefore = await getAllBalances(walletAddr, tokenContracts);

                let amounts = Array(tokenList.length).fill(0);
                amounts[0] = amt;

                await firstAsset.connect(walletSigner).approve(StableVaultAddr, MAX_UINT256);
                await StablePool.connect(walletSigner).addLiquidity(amounts, 0, 999999999999999);

                const balsAfter = await getAllBalances(walletAddr, tokenContracts);
                const postTokenAmt = ethers.utils.formatEther(await StablePool.getTokenBalance(0));

                expect(Number(preTokenAmt), "Pool balance not deducted correctly").to.be.lessThan(Number(postTokenAmt));
                expect(Number(balsBefore[0])).to.be.greaterThan(Number(balsAfter[0]));
            })

            it("reverts when the pool is paused", async () => {
                await StablePool.connect(deployer).pause();
                const paused = await StablePool.paused();
                expect(paused, "Pool isn't being paused").to.be.true;

                let amounts = Array(tokenList.length).fill(0);
                amounts[0] = ethers.utils.parseEther("500");
                await expect(StablePool.connect(walletSigner).addLiquidity(amounts, 0, 999999999999999)).to.be.reverted;
            })

            it("multiple tokens can be added at same time", async () => {
                const firstAsset = tokenContracts[1];
                const secondAsset = tokenContracts[2];
                const txnAmt = "3700";
                const amt = ethers.utils.parseEther(txnAmt);
                const preTokenAmtA = ethers.utils.formatEther(await StablePool.getTokenBalance(1));
                const preTokenAmtB = ethers.utils.formatEther(await StablePool.getTokenBalance(2));
                const balsBefore = await getAllBalances(walletAddr, tokenContracts);

                let amounts = Array(tokenList.length).fill(0);
                amounts[1] = amt;
                amounts[2] = amt;

                await firstAsset.connect(walletSigner).approve(StableVaultAddr, MAX_UINT256);
                await secondAsset.connect(walletSigner).approve(StableVaultAddr, MAX_UINT256);
                await StablePool.connect(walletSigner).addLiquidity(amounts, 0, MAX_UINT256);

                const balsAfter = await getAllBalances(walletAddr, tokenContracts);
                const postTokenAmtA = ethers.utils.formatEther(await StablePool.getTokenBalance(1));
                const postTokenAmtB = ethers.utils.formatEther(await StablePool.getTokenBalance(2));

                expect(Number(balsBefore[1])).to.be.greaterThan(Number(balsAfter[1]));
                expect(Number(balsBefore[2])).to.be.greaterThan(Number(balsAfter[2]));
                expect(Number(postTokenAmtA), "TokenA amount not increased in pool").to.be.greaterThan(Number(preTokenAmtA));
                expect(Number(postTokenAmtB), "TokenB amount not increased in pool").to.be.greaterThan(Number(preTokenAmtB));
            })


            it("the liquidity can be removed equally", async () => {
                let amounts = Array(tokenList.length).fill(0);
                let liquidity = "12000";
                let txn = ethers.utils.parseEther(liquidity);
                let balsBefore = await getAllBalances(walletAddr, tokenContracts);

                await StablePoolToken.connect(walletSigner).approve(StableVaultAddr, MAX_UINT256);
                await StablePool.connect(walletSigner).removeLiquidity(txn, amounts, MAX_UINT256);

                const balsAfter = await getAllBalances(walletAddr, tokenContracts);

                // Check that each token balance has been increased for user when withdrawing liquidity
                let diffs = Array();
                for (let i in balsAfter) {
                    expect(Number(balsAfter[i]), `Balance of item ${i} is not increased`).to.be.greaterThan(Number(balsBefore[i]));
                    diffs.push(Number(balsAfter[i]) - Number(balsBefore[i]));
                }

                // Check that the total amount withdrawn is roughly that of the withdrawal amount
                let total = 0;
                for (let item of diffs) {
                    total += Number(item);
                    //log(`item is ${item}`);
                }
                //log(`total is ${total}`);
                log(`\tLiquidity withdrawn is ${liquidity} compared to balance increased by ${total}`);
                let ratio = Number(total) / Number(liquidity);
                // TODO: Investigate why there's so much slippage, as in why we get hardly any TUSD back
                expect(ratio, "User receives less balance than liquidity withdrawn").to.be.greaterThan(0.80);
            })

            it("the liquidity can be removed one-sided", async () => {
                let amounts = Array(tokenList.length).fill(0);
                let liquidity = "1200";
                let index = 1;
                let txn = ethers.utils.parseEther(liquidity);
                let balsBefore = await getAllBalances(walletAddr, tokenContracts);

                await StablePoolToken.connect(walletSigner).approve(StableVaultAddr, MAX_UINT256);
                await StablePool.connect(walletSigner).removeLiquidityOneToken(txn, index, amounts, MAX_UINT256);

                const balsAfter = await getAllBalances(walletAddr, tokenContracts);

                expect(Number(balsAfter[index])).to.be.greaterThan(Number(balsBefore[index]))
                expect(Number(balsBefore[index + 1])).to.be.equals(Number(balsBefore[index + 1]))
            })

        })

        describe("When swapping tokens", async () => {
            it("can swap tokenA for tokenB", async () => {
                const txnAmt = "25000";
                let amt = ethers.utils.parseEther(txnAmt);
                const balsBefore = await getAllBalances(walletAddr, tokenContracts);

                await approveAll(tokenContracts, StableVaultAddr);
                await StablePool.connect(walletSigner).swap(0, 1, amt, 0, 999999999999999);

                const balsAfter = await getAllBalances(walletAddr, tokenContracts);

                expect(Number(balsBefore[0])).to.be.greaterThan(Number(balsAfter[0]));
                expect(Number(balsBefore[1])).to.be.lessThan(Number(balsAfter[1]));
                expect(Number(balsBefore[2])).to.be.equals(Number(balsAfter[2]));
                expect(Number(balsBefore[3])).to.be.equals(Number(balsAfter[3]));
            })

            if (tokenList.length > 2) {
                it("can swap tokenB for tokenC", async () => {
                    const txnAmt = "25000";
                    let amt = ethers.utils.parseEther(txnAmt);
                    const balsBefore = await getAllBalances(walletAddr, tokenContracts);

                    await approveAll(tokenContracts, StableVaultAddr);
                    await StablePool.connect(walletSigner).swap(1, 2, amt, 0, 999999999999999);

                    const balsAfter = await getAllBalances(walletAddr, tokenContracts);

                    expect(Number(balsBefore[0])).to.be.equals(Number(balsAfter[0]));
                    expect(Number(balsBefore[1])).to.be.greaterThan(Number(balsAfter[1]));
                    expect(Number(balsBefore[2])).to.be.lessThan(Number(balsAfter[2]));
                    expect(Number(balsBefore[3])).to.be.equals(Number(balsAfter[3]));
                })

                if (tokenList.length > 3) {
                    it("can swap tokenC for tokenD", async () => {
                        const txnAmt = "25000";
                        let amt = ethers.utils.parseEther(txnAmt);
                        const balsBefore = await getAllBalances(walletAddr, tokenContracts);

                        await approveAll(tokenContracts, StableVaultAddr);
                        await StablePool.connect(walletSigner).swap(2, 3, amt, 0, 999999999999999);

                        const balsAfter = await getAllBalances(walletAddr, tokenContracts);

                        expect(Number(balsBefore[0])).to.be.equals(Number(balsAfter[0]));
                        expect(Number(balsBefore[1])).to.be.equals(Number(balsAfter[1]));
                        expect(Number(balsBefore[2])).to.be.greaterThan(Number(balsAfter[2]));
                        expect(Number(balsBefore[3])).to.be.lessThan(Number(balsAfter[3]));
                    })

                    it("can swap tokenD for tokenA", async () => {
                        const txnAmt = "25000";
                        let amt = ethers.utils.parseEther(txnAmt);
                        const balsBefore = await getAllBalances(walletAddr, tokenContracts);

                        await approveAll(tokenContracts, StableVaultAddr);
                        await StablePool.connect(walletSigner).swap(3, 0, amt, 0, 999999999999999);

                        const balsAfter = await getAllBalances(walletAddr, tokenContracts);

                        expect(Number(balsBefore[0])).to.be.lessThan(Number(balsAfter[0]));
                        expect(Number(balsBefore[1])).to.be.equals(Number(balsAfter[1]));
                        expect(Number(balsBefore[2])).to.be.equals(Number(balsAfter[2]));
                        expect(Number(balsBefore[3])).to.be.greaterThan(Number(balsAfter[3]));
                    })
                }
            }

        })

        describe("When minimum amounts are requested", async () => {
            it("fails when swap slippage is too high", async () => {
                let amt = "1200";
                let txn = ethers.utils.parseEther(amt);
                const balsBefore = await getAllBalances(walletAddr, tokenContracts);

                await expect(StablePool.connect(walletSigner).swap(0, 1, txn, txn, 999999999999999)).to.be.revertedWith("Swap didn't result in min tokens");

                const balsAfter = await getAllBalances(walletAddr, tokenContracts);

                for (let i in balsBefore) {
                    expect(Number(balsBefore[i]), `Balance[${i}] should be unaffected by failed swap`).to.be.equals(Number(balsAfter[i]));
                }

            })

            it("fails when addLiquidity slippage is too high", async () => {
                const firstAsset = tokenContracts[0];

                await firstAsset.connect(walletSigner).approve(StableVaultAddr, MAX_UINT256);
                const txnAmt = "2500";
                const amt = ethers.utils.parseEther(txnAmt);

                const preTokenAmt = ethers.utils.formatEther(await StablePool.getTokenBalance(0));
                const balsBefore = await getAllBalances(walletAddr, tokenContracts);

                let amounts = Array(tokenList.length).fill(0);
                amounts[0] = amt;
                await expect(StablePool.connect(walletSigner).addLiquidity(amounts, amt, 999999999999999)).to.be.reverted;

                const balsAfter = await getAllBalances(walletAddr, tokenContracts);
                const postTokenAmt = ethers.utils.formatEther(await StablePool.getTokenBalance(0));
                let match = verifyBalances(balsBefore, balsAfter);

                expect(match, `User balances should be unaffected by failed addLiquidity`).to.be.true;
                expect(Number(preTokenAmt), "Pool balance should be unaffected by failed addLiquidity").to.be.equals(Number(postTokenAmt));
            })

            it("fails when removeLiquidity slippage is too high", async () => {
                let liquidity = "12000";
                let txn = ethers.utils.parseEther(liquidity);
                let amounts = Array(tokenList.length).fill(txn);

                const preTokenAmt = ethers.utils.formatEther(await StablePool.getTokenBalance(0));
                const balsBefore = await getAllBalances(walletAddr, tokenContracts);

                await StablePoolToken.connect(walletSigner).approve(StableVaultAddr, MAX_UINT256);
                await expect(StablePool.connect(walletSigner).removeLiquidity(txn, amounts, MAX_UINT256)).to.be.reverted;

                const balsAfter = await getAllBalances(walletAddr, tokenContracts);
                const postTokenAmt = ethers.utils.formatEther(await StablePool.getTokenBalance(0));
                let match = verifyBalances(balsBefore, balsAfter);

                expect(match, `User balances should be unaffected by failed removeLiquidity`).to.be.true;
                expect(Number(preTokenAmt), "Pool balance should be unaffected by failed removeLiquidity").to.be.equals(Number(postTokenAmt));
            })
        })
    })

    async function approveAll(tokenList: Array<Contract>, address: string) {
        for (let item of tokenList) {
            await item.approve(address, MAX_UINT256);
        }
    }

    function verifyBalances(pre: Array<string>, post: Array<string>) {
        let bool = true;
        for (let i in pre) {
            if (pre[i] != post[i]) {
                bool = false
            }
        };
        return bool
    }

    async function getAllBalances(address: string, tokenContracts: Array<Contract>) {
        let balances = Array();
        let string = Array();
        for (let contract of tokenContracts) {
            let bal = ethers.utils.formatEther(await contract.balanceOf(address));
            let num = Number(bal).toFixed(2);
            balances.push(bal);
            string.push(num + " " + await contract.symbol())
        };
        log(`\tBalances of user are: ${string}`);

        return balances
    }

}
