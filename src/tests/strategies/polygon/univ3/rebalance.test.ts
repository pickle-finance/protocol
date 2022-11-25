import "@nomicfoundation/hardhat-toolbox";
import { ethers } from "hardhat";
import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect, deployContract, toWei, unlockAccount } from "../../../utils/testHelper";
import { ethers as ethersjs, BigNumber, Contract } from "ethers";
import { Signer } from "@ethersproject/abstract-signer";
import { getContractAt } from "../../../utils/testHelper";
import Safe, { SafeConfig, SafeFactory, SafeAccountConfig } from "@gnosis.pm/safe-core-sdk";
import { SafeTransactionDataPartial, SafeTransaction } from "@gnosis.pm/safe-core-sdk-types";
import EthersAdapter, { EthersAdapterConfig } from "@gnosis.pm/safe-ethers-lib";

/**
 * @notice takes a gnosis safe address and returns a list of Safe instances each with a unique owner,
 * the length of the array is the minimum threshold needed to execute a gnosis safe transaction
 */
const getSafesWithOwners = async (safeAddress: string): Promise<Safe[]> => {
  // prettier-ignore
  const safeAbi = ["function getOwners() view returns(address[])", "function getThreshold() view returns(uint256)"];
  const safeContract = new ethers.Contract(safeAddress, safeAbi, await ethers.getSigners().then((x) => x[0]));
  const ownersAddresses: string[] = await safeContract.getOwners();
  const threshold = await safeContract.getThreshold().then((x: BigNumber) => x.toNumber());
  const neededOwnersAddresses = ownersAddresses.slice(0, threshold);

  const ethAdapters: EthersAdapter[] = await Promise.all(
    neededOwnersAddresses.map(async ownerAddr => new EthersAdapter({ ethers, signer: await unlockAccount(ownerAddr) }))
  );

  const safeWithOwners: Safe[] = await Promise.all(
    ethAdapters.map(async ethAdapter => await Safe.create({ safeAddress, ethAdapter }))
  );

  return safeWithOwners;
};
/**
 * @param targetContract the target contract
 * @param funcName the target function name on the contract. (e.g, "transfer")
 * @param funcArgs the arguments of the target function (e.g, ["0x000...",BigNumber.from("10000000000")]
 */
const getSafeTxnData = (targetContract: ethersjs.Contract, funcName: string, funcArgs: any[]) => {
  const data = targetContract.interface.encodeFunctionData(funcName, funcArgs);
  const safeTransactionData: SafeTransactionDataPartial = {
    to: targetContract.address,
    data,
    value: "0",
    safeTxGas: 1800000,
  };
  return safeTransactionData;
};

const executeSafeTxn = async (safeTransactionData: SafeTransactionDataPartial, safesWithOwners: Safe[]) => {
  const safeTxn: SafeTransaction = await safesWithOwners[0].createTransaction({ safeTransactionData });
  const txHash = await safesWithOwners[0].getTransactionHash(safeTxn);

  await Promise.all(safesWithOwners.map(async safe => await (await safe.approveTransactionHash(txHash)).transactionResponse?.wait()));
  const executeTxResponse = await safesWithOwners[0].executeTransaction(safeTxn);
  return await executeTxResponse.transactionResponse?.wait();
};

const sendGnosisSafeTxn = async (
  safeAddress: string,
  targetContract: ethersjs.Contract,
  funcName: string,
  funcArgs: any[]
) => {
  const safesWithOwners = await getSafesWithOwners(safeAddress);
  const txnData = getSafeTxnData(targetContract, funcName, funcArgs);
  const txnReceipt = await executeSafeTxn(txnData, safesWithOwners);
  return txnReceipt;
};

describe("UniV3 Strategy", () => {
  const setupFixture = async () => {
    const [alice, governance, treasury, bob, charles, fred] = await ethers.getSigners();

    // Controller setup
    const controller = await deployContract(
      "/src/optimism/controller-v7.sol:ControllerV7",
      governance.address,
      governance.address,
      governance.address,
      governance.address,
      treasury.address
    );

    // Strategy setup
    const strategyContractName =
      "src/strategies/polygon/uniswapv3/strategy-univ3-usdc-usdt-lp.sol:StrategyUsdcUsdtUniV3StakerPoly";
    const strategy = await deployContract(
      strategyContractName,
      500,
      governance.address,
      governance.address,
      controller.address,
      governance.address
    );
    const token0 = await getContractAt("src/lib/erc20.sol:ERC20", await strategy.token0());
    const token1 = await getContractAt("src/lib/erc20.sol:ERC20", await strategy.token1());
    const token0name = await token0.name();
    const token1name = await token1.name();
    const poolAddr = await strategy.pool();

    // Jar setup
    const jarContract = "src/polygon/pickle-jar-univ3.sol:PickleJarUniV3Poly";
    const jarDescrip = `pickling ${token0name}/${token1name} Jar`;
    const pTokenName = `p${token0name}${token0name}`;
    const jar = await deployContract(
      jarContract,
      jarDescrip,
      pTokenName,
      poolAddr,
      governance.address,
      governance.address,
      controller.address
    );
    await controller.connect(governance).setJar(poolAddr, jar.address);
    await controller.connect(governance).approveStrategy(poolAddr, strategy.address);
    await controller.connect(governance).setStrategy(poolAddr, strategy.address);

    // Borked strategy
    // const safeAbi = [
    //   // { "inputs": [{ "internalType": "address", "name": "to", "type": "address" }, { "internalType": "uint256", "name": "value", "type": "uint256" }, { "internalType": "bytes", "name": "data", "type": "bytes" }, { "internalType": "enum Enum.Operation", "name": "operation", "type": "uint8" }, { "internalType": "uint256", "name": "safeTxGas", "type": "uint256" }, { "internalType": "uint256", "name": "baseGas", "type": "uint256" }, { "internalType": "uint256", "name": "gasPrice", "type": "uint256" }, { "internalType": "address", "name": "gasToken", "type": "address" }, { "internalType": "address payable", "name": "refundReceiver", "type": "address" }, { "internalType": "bytes", "name": "signatures", "type": "bytes" }], "name": "execTransaction", "outputs": [{ "internalType": "bool", "name": "", "type": "bool" }], "stateMutability": "payable", "type": "function" }
    //   "function execTransaction(address to, uint256 value, bytes data, uint8 operation, uint256 safeTxGas, uint256 baseGas, uint256 gasPrice, address gasToken, address payable refundReceiver, bytes signatures) payable returns(bool)",
    //   "function getTransactionHash(address to, uint256 value, bytes calldata data, uint8 operation, uint256 safeTxGas, uint256 baseGas, uint256 gasPrice, address gasToken, address refundReceiver, uint256 _nonce) view returns (bytes32)",
    //   "function approveHash(bytes32 hashToApprove)",
    //
    // ];

    // Transfer Liquidity position from the bad strategy to the new one
    const badStrat = await getContractAt(strategyContractName, "0x5BEF03597A205F54DB1769424008aEC11e8b0dCB");
    const timelockAddress = await badStrat.timelock();
    const tokenId = await badStrat.tokenId();
    const nftManAddr = await badStrat.nftManager();
    const nftManAbi = ["function transferFrom(address from, address to, uint256 tokenId)"];
    const txnData = new ethersjs.Contract(nftManAddr, nftManAbi).interface.encodeFunctionData("transferFrom", [
      badStrat.address,
      strategy.address,
      tokenId,
    ]);
    const safeTxnReceipt = await sendGnosisSafeTxn(timelockAddress, badStrat, "execute", [nftManAddr, txnData]);

    return { strategy, governance, jar, token0, token1 };
  };

  describe("Strategy Rebalance", () => {
    it("Should rebalance with minimal amounts in strategy", async () => { });
    it("test gnosis safe", async () => {
      const blockNumberBefore = await (await ethers.getSigners().then((x) => x[0])).provider?.getBlockNumber();
      const { governance } = await loadFixture(setupFixture);
      const blockNumberAfter = await governance.provider.getBlockNumber();

      console.log("Block Number Before: " + blockNumberBefore);
      console.log("Block Number After: " + blockNumberAfter);
    });
    it("test transfer", async () => {
      const multisigAddr = "0xeae55893cc8637c16cf93d43b38aa022d689fa62";
      const tokenAddr = "0x7ceb23fd6bc0add59e62ac25578270cff1b9f619";
      const toAddr = "0x33236B5B99d52E8366964c43F4211b959855eb0C";
      const abi = ["function transfer(address recipient, uint256 amount) returns(bool)", "function balanceOf(address) view returns(uint256)"];
      const tokenContract = await ethers.getContractAt(abi, tokenAddr);
      const txnData = tokenContract.interface.encodeFunctionData("transfer", [toAddr, ethers.utils.parseEther("1")]);
      const balBefore = await tokenContract.balanceOf(toAddr);

      const safeTxnReceipt = await sendGnosisSafeTxn(multisigAddr, tokenContract, "transfer", [toAddr, ethers.utils.parseEther("1")]);

      const balAfter = await tokenContract.balanceOf(toAddr);
      console.log("Before: " + ethers.utils.formatEther(balBefore));
      console.log("After: " + ethers.utils.formatEther(balAfter));
    })


    it.only("test nft transfer 1", async () => {
      const multisigAddr = "0xeae55893cc8637c16cf93d43b38aa022d689fa62";
      const recipient = "0x33236B5B99d52E8366964c43F4211b959855eb0C";
      const tokenId = BigNumber.from(470244);

      const nftManAddr = "0xc36442b4a4522e871399cd717abdd847ab11fe88";
      const nftManAbi = ["function transferFrom(address from, address to, uint256 tokenId)", "function ownerOf(uint256) view returns(address)"];
      const nftContract = await ethers.getContractAt(nftManAbi, nftManAddr);

      const badStrat = "0x5bef03597a205f54db1769424008aec11e8b0dcb";
      const badStratAbi = ["function execute(address _target, bytes _data) payable returns (bytes response)"];
      const badStratContract = await ethers.getContractAt(badStratAbi, badStrat);

      const proxyContract = await deployContract("src/strategies/polygon/uniswapv3/proxy.sol:Proxy");
      const txnData = proxyContract.interface.encodeFunctionData("transferFrom", [nftContract.address, badStrat, recipient, tokenId]);

      const ownerBefore = await nftContract.ownerOf(tokenId);

      const safeTxnReceipt = await sendGnosisSafeTxn(multisigAddr, badStratContract, "execute", [proxyContract.address, txnData]);

      const ownerAfter = await nftContract.ownerOf(tokenId);
      console.log("Before: " + ownerBefore);
      console.log("After: " + ownerAfter);
    })

    it.only("test nft transfer 2", async () => {
      const multisigAddr = "0xeae55893cc8637c16cf93d43b38aa022d689fa62";
      const recipient = "0x33236B5B99d52E8366964c43F4211b959855eb0C";
      const tokenId = BigNumber.from(470244);

      const nftManAddr = "0xc36442b4a4522e871399cd717abdd847ab11fe88";
      const nftManAbi = ["function transferFrom(address from, address to, uint256 tokenId)", "function ownerOf(uint256) view returns(address)"];
      const nftContract = await ethers.getContractAt(nftManAbi, nftManAddr);

      const badStrat = "0x5bef03597a205f54db1769424008aec11e8b0dcb";
      const badStratAbi = ["function execute(address _target, bytes _data) payable returns (bytes response)"];
      const badStratContract = await ethers.getContractAt(badStratAbi, badStrat);

      const proxyContract = await deployContract("src/strategies/polygon/uniswapv3/proxy.sol:Proxy");
      const txnData1 = nftContract.interface.encodeFunctionData("transferFrom", [badStrat, recipient, tokenId]);
      const txnData2 = proxyContract.interface.encodeFunctionData("proxyExecute", [nftContract.address, txnData1]);
      ethers.utils.defaultAbiCoder.

      const ownerBefore = await nftContract.ownerOf(tokenId);

      const safeTxnReceipt = await sendGnosisSafeTxn(multisigAddr, badStratContract, "execute", [proxyContract.address, txnData2]);

      const ownerAfter = await nftContract.ownerOf(tokenId);
      console.log("Before: " + ownerBefore);
      console.log("After: " + ownerAfter);
    })
  });
});
