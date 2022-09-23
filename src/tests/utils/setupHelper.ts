import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";
import { BigNumber, BigNumberish, Contract } from "ethers";
import {
  expect,
  getContractAt,
  deployContract,
  unlockAccount,
  toWei,
} from "./testHelper";
import { WETH } from "./constants";

/**
 * @notice get the unix timestamp
 * @returns current timestamp
 */
const now = () => {
  return Math.floor(new Date().getTime() / 1000);
};

/**
 * @notice setup the controller, strategy and picklejar
 * @param strategyName strategy name to be deployed
 * @param want want token to be set
 * @param governance governance signer addr
 * @param strategist strategy signer addr
 * @param timelock timelock signer addr
 * @param devfund devfund signer addr
 * @param treasury treasury signeraddr
 * @returns controller, strategy and picklejar contract
 */
export const setup = async (
  strategyName: string,
  want: Contract,
  governance: SignerWithAddress,
  strategist: SignerWithAddress,
  timelock: SignerWithAddress,
  devfund: SignerWithAddress,
  treasury: SignerWithAddress,
  isPolygon = false
) => {
  const controller = await deployContract(
    isPolygon
      ? "src/polygon/controller-v4.sol:ControllerV4"
      : "src/controller-v4.sol:ControllerV4",
    governance.address,
    strategist.address,
    timelock.address,
    devfund.address,
    treasury.address
  );
  console.log("✅ Controller is deployed at ", controller.address);

  const strategy = await deployContract(
    strategyName,
    governance.address,
    strategist.address,
    controller.address,
    timelock.address
  );
  console.log("✅ Strategy is deployed at ", strategy.address);

  const pickleJar = await deployContract(
    "src/pickle-jar.sol:PickleJar",
    want.address,
    governance.address,
    timelock.address,
    controller.address
  );
  console.log("✅ PickleJar is deployed at ", pickleJar.address);

  await controller.setJar(want.address, pickleJar.address);
  await controller.approveStrategy(want.address, strategy.address);
  await controller.setStrategy(want.address, strategy.address);

  return [controller, strategy, pickleJar];
};

export const setupWithPickleJar = async (
  pickleJarName: string,
  strategyName: string,
  want: Contract,
  governance: SignerWithAddress,
  strategist: SignerWithAddress,
  timelock: SignerWithAddress,
  devfund: SignerWithAddress,
  treasury: SignerWithAddress,
  isPolygon = false
) => {
  const controller = await deployContract(
    isPolygon
      ? "src/polygon/controller-v4.sol:ControllerV4"
      : "src/controller-v4.sol:ControllerV4",
    governance.address,
    strategist.address,
    timelock.address,
    devfund.address,
    treasury.address
  );
  console.log("✅ Controller is deployed at ", controller.address);

  const strategy = await deployContract(
    strategyName,
    governance.address,
    strategist.address,
    controller.address,
    timelock.address
  );
  console.log("✅ Strategy is deployed at ", strategy.address);

  const pickleJar = await deployContract(
    pickleJarName,
    want.address,
    governance.address,
    timelock.address,
    controller.address
  );
  console.log("✅ PickleJar is deployed at ", pickleJar.address);

  await controller.setJar(want.address, pickleJar.address);
  await controller.approveStrategy(want.address, strategy.address);
  await controller.setStrategy(want.address, strategy.address);

  return [controller, strategy, pickleJar];
};

/**
 * @notice get erc20 token from uniswap/sushiswap
 * @param routerAddr router address(uni or sushi)
 * @param token token address
 * @param amount token amount
 * @param from from address that receives token
 */
export const getERC20 = async (
  routerAddr: string,
  token: string,
  amount: BigNumberish,
  from: SignerWithAddress
) => {
  const path = [WETH, token];
  await getERC20WithPath(routerAddr, token, amount, path, from);
};

/**
 * @notice get erc20 token from uniswap/sushiswap using swap path
 * @param routerAddr router address(uni or sushi)
 * @param token token address
 * @param amount token amount
 * @param path swap path
 * @param from from address that receives token
 */
export const getERC20WithPath = async (
  routerAddr: string,
  token: string,
  amount: BigNumberish,
  path: string[],
  from: SignerWithAddress
) => {
  const router = await getContractAt("UniswapRouterV2", routerAddr);

  const ins = await router.connect(from).getAmountsIn(amount, path);
  const ethAmountIn = ins[0];

  await router
    .connect(from)
    .swapETHForExactTokens(amount, path, from.address, now() + 60, {
      value: ethAmountIn,
    });

  const tokenContract = await getContractAt("src/lib/erc20.sol:ERC20", token);
  const _balance = await tokenContract.balanceOf(from.address);

  expect(_balance).to.be.gte(amount, "get erc20 failed");
};

/**
 * @notice get erc20 token from uniswap/sushiswap using eth
 * @param routerAddr router address(uni or sushi)
 * @param token token address
 * @param ethAmount eth amount to be spent
 * @param from from address that receives token
 */
export const getERC20WithETH = async (
  routerAddr: string,
  token: string,
  ethAmount: BigNumberish,
  from: SignerWithAddress
) => {
  const router = await getContractAt("UniswapRouterV2", routerAddr);

  const path = [WETH, token];
  await router
    .connect(from)
    .swapExactETHForTokens(0, path, from.address, now() + 60, {
      value: ethAmount,
    });

  const tokenContract = await getContractAt("src/lib/erc20.sol:ERC20", token);
  const _balance = await tokenContract.balanceOf(from.address);

  expect(_balance).to.be.gt(0, "get erc20 failed");
};

/**
 * @notice get lp token from uni/sushiswap
 * @param routerAddr router address
 * @param lpToken lp token address to get
 * @param ethAmount eth amount to be spent
 * @param from receive address
 */
export const getLpToken = async (
  routerAddr: string,
  lpToken: string,
  ethAmount: BigNumber,
  from: SignerWithAddress
) => {
  const router = await getContractAt("UniswapRouterV2", routerAddr);
  const lpTokenContract = await getContractAt("IUniswapV2Pair", lpToken);

  const token0 = await lpTokenContract.token0();
  const token1 = await lpTokenContract.token1();
  const wethContract = await getContractAt("WETH", WETH);

  if (token0.toLowerCase() != WETH.toLowerCase())
    await getERC20WithETH(routerAddr, token0, ethAmount.div(2), from);
  else await wethContract.deposit({ value: ethAmount.div(2) });

  if (token1.toLowerCase() != WETH.toLowerCase())
    await getERC20WithETH(routerAddr, token1, ethAmount.div(2), from);
  else await wethContract.deposit({ value: ethAmount.div(2) });

  const token0Contract = await getContractAt("src/lib/erc20.sol:ERC20", token0);
  const token1Contract = await getContractAt("src/lib/erc20.sol:ERC20", token1);

  const _balance0 = await token0Contract.balanceOf(from.address);
  const _balance1 = await token1Contract.balanceOf(from.address);

  await token0Contract.connect(from).approve(router.address, _balance0);
  await token1Contract.connect(from).approve(router.address, _balance1);

  await router.addLiquidity(
    token0,
    token1,
    _balance0,
    _balance1,
    0,
    0,
    from.address,
    now() + 60
  );

  const _lpBalance = await lpTokenContract.balanceOf(from.address);
  expect(_lpBalance).to.be.gt(0, "get lp token failed");
};

/**
 * @dev get want token from the whale using impersonating account feature
 * @param want want token instance
 * @param amount token amount
 * @param to receive address
 * @param whaleAddr whale address to send tokens
 */
export const getWantFromWhale = async (
  want_addr: string,
  amount: number | BigNumber,
  to: SignerWithAddress,
  whaleAddr: string
) => {
  const whale = await unlockAccount(whaleAddr);
  const want = await getContractAt("src/lib/erc20.sol:ERC20", want_addr);

  await want.connect(whale).transfer(to.address, amount);
  const _balance = await want.balanceOf(to.address);
  expect(_balance).to.be.gte(amount, "get want from the whale failed");
};
