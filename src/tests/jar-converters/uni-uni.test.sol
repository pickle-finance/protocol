// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../lib/hevm.sol";
import "../lib/user.sol";
import "../lib/test-approx.sol";
import "../lib/test-defi-base.sol";

import "../../interfaces/strategy.sol";
import "../../interfaces/curve.sol";
import "../../interfaces/uniswapv2.sol";

import "../../pickle-jar.sol";
import "../../controller-v4.sol";

import "../../jar-converters/uni-uni-converter.sol";

import "../../strategies/uniswapv2/strategy-uni-eth-dai-lp-v3_1.sol";
import "../../strategies/uniswapv2/strategy-uni-eth-usdt-lp-v3_1.sol";
import "../../strategies/uniswapv2/strategy-uni-eth-usdc-lp-v3_1.sol";
import "../../strategies/uniswapv2/strategy-uni-eth-wbtc-lp-v1.sol";

contract StrategyUniUniJarSwapTest is DSTestDefiBase {
    address governance;
    address strategist;
    address devfund;
    address treasury;
    address timelock;

    IStrategy[] uniStrategies;
    PickleJar[] uniPickleJars;

    ControllerV4 controller;

    UniUniJarConverter uniUniJarConverter;

    // Contract wide variable to avoid stack too deep errors
    uint256 temp;

    function setUp() public {
        governance = address(this);
        strategist = address(this);
        devfund = address(new User());
        treasury = address(new User());
        timelock = address(this);

        controller = new ControllerV4(
            governance,
            strategist,
            timelock,
            devfund,
            treasury
        );

        // Uni strategies
        uniStrategies = new IStrategy[](4);
        uniPickleJars = new PickleJar[](uniStrategies.length);
        uniStrategies[0] = IStrategy(
            address(
                new StrategyUniEthDaiLpV3_1(
                    governance,
                    strategist,
                    address(controller),
                    timelock
                )
            )
        );
        uniStrategies[1] = IStrategy(
            address(
                new StrategyUniEthUsdcLpV3_1(
                    governance,
                    strategist,
                    address(controller),
                    timelock
                )
            )
        );
        uniStrategies[2] = IStrategy(
            address(
                new StrategyUniEthUsdtLpV3_1(
                    governance,
                    strategist,
                    address(controller),
                    timelock
                )
            )
        );
        uniStrategies[3] = IStrategy(
            address(
                new StrategyUniEthWBtcLpV1(
                    governance,
                    strategist,
                    address(controller),
                    timelock
                )
            )
        );

        for (uint256 i = 0; i < uniStrategies.length; i++) {
            uniPickleJars[i] = new PickleJar(
                uniStrategies[i].want(),
                governance,
                timelock,
                address(controller)
            );

            controller.setJar(
                uniStrategies[i].want(),
                address(uniPickleJars[i])
            );
            controller.approveStrategy(
                uniStrategies[i].want(),
                address(uniStrategies[i])
            );
            controller.setStrategy(
                uniStrategies[i].want(),
                address(uniStrategies[i])
            );
        }

        uniUniJarConverter = new UniUniJarConverter();

        controller.approveJarConverter(address(uniUniJarConverter));

        hevm.warp(startTime);
    }

    function _getUniLP(
        address lp,
        uint256 ethAmount,
        uint256 otherAmount
    ) internal {
        IUniswapV2Pair fromPair = IUniswapV2Pair(lp);

        address other = fromPair.token0() != weth
            ? fromPair.token0()
            : fromPair.token1();

        _getERC20(other, otherAmount);

        uint256 _other = IERC20(other).balanceOf(address(this));

        IERC20(other).safeApprove(address(univ2), 0);
        IERC20(other).safeApprove(address(univ2), _other);

        univ2.addLiquidityETH{value: ethAmount}(
            other,
            _other,
            0,
            0,
            address(this),
            now + 60
        );
    }

    struct TestParams {
        address from; // Uniswap LP
        address fromUnderlying; // The other side of the weth pair
        address to; // Uniswap LP, always assumes its a weth pair
        address toUnderlying; // The other side of the weth pair
    }

    function _test_uni_uni_swap(
        uint256 fromIndex,
        uint256 toIndex,
        uint256 amount,
        bytes memory _data
    ) internal {
        TestParams memory params = abi.decode(_data, (TestParams));

        // Deposit into PickleJars
        address from = address(uniPickleJars[fromIndex].token());

        _getUniLP(from, 1e18, amount);

        uint256 _from = IERC20(from).balanceOf(address(this));
        IERC20(from).approve(address(uniPickleJars[fromIndex]), _from);
        uniPickleJars[fromIndex].deposit(_from);
        uniPickleJars[fromIndex].earn();

        // Swap!
        uint256 _fromPickleJar = IERC20(address(uniPickleJars[fromIndex]))
            .balanceOf(address(this));
        IERC20(address(uniPickleJars[fromIndex])).approve(
            address(controller),
            _fromPickleJar
        );

        bytes memory data = abi.encode(
            params.from,
            params.fromUnderlying,
            params.to,
            params.toUnderlying
        );

        // Check minimum amount
        try
            controller.swapExactJarForJar(
                address(uniPickleJars[fromIndex]),
                address(uniPickleJars[toIndex]),
                _fromPickleJar,
                uint256(-1), // Min receive amount
                address(uniUniJarConverter),
                data
            )
         {
            revert("min-amount-should-fail");
        } catch {}

        uint256 _beforeTo = IERC20(address(uniPickleJars[toIndex])).balanceOf(
            address(this)
        );
        uint256 _beforeFrom = IERC20(address(uniPickleJars[fromIndex]))
            .balanceOf(address(this));
        uint256 _beforeDev = IERC20(from).balanceOf(devfund);
        uint256 _beforeTreasury = IERC20(from).balanceOf(treasury);

        temp = controller.swapExactJarForJar(
            address(uniPickleJars[fromIndex]),
            address(uniPickleJars[toIndex]),
            _fromPickleJar,
            0, // Min receive amount
            address(uniUniJarConverter),
            data
        );

        uint256 _afterTo = IERC20(address(uniPickleJars[toIndex])).balanceOf(
            address(this)
        );
        uint256 _afterFrom = IERC20(address(uniPickleJars[fromIndex]))
            .balanceOf(address(this));
        uint256 _afterDev = IERC20(from).balanceOf(devfund);
        uint256 _afterTreasury = IERC20(from).balanceOf(treasury);

        uint256 treasuryEarned = _afterTreasury.sub(_beforeTreasury);

        assertEq(treasuryEarned, _afterDev.sub(_beforeDev));
        assertTrue(treasuryEarned > 0);
        assertEqApprox(
            _fromPickleJar.mul(controller.convenienceFee()).div(
                controller.convenienceFeeMax()
            ),
            treasuryEarned.mul(2)
        );
        assertTrue(_afterTo.sub(_beforeTo) > 0);
        assertEq(_afterTo.sub(_beforeTo), temp);
        assertTrue(_afterFrom < _beforeFrom);
        assertTrue(_afterTo > _beforeTo);
        assertEq(_afterFrom, 0);
    }

    // Tests
    function test_jar_converter_uni_uni_0_1() public {
        uint256 fromIndex = 0;
        uint256 toIndex = 1;
        uint256 amount = 400e18;

        address from = univ2Factory.getPair(weth, dai);
        address fromUnderlying = dai;

        address to = univ2Factory.getPair(weth, usdc);
        address toUnderlying = usdc;

        _test_uni_uni_swap(
            fromIndex,
            toIndex,
            amount,
            abi.encode(from, fromUnderlying, to, toUnderlying)
        );
    }

    function test_jar_converter_uni_uni_0_2() public {
        uint256 fromIndex = 0;
        uint256 toIndex = 2;
        uint256 amount = 400e18;

        address from = univ2Factory.getPair(weth, dai);
        address fromUnderlying = dai;

        address to = univ2Factory.getPair(weth, usdt);
        address toUnderlying = usdt;

        _test_uni_uni_swap(
            fromIndex,
            toIndex,
            amount,
            abi.encode(from, fromUnderlying, to, toUnderlying)
        );
    }

    function test_jar_converter_uni_uni_0_3() public {
        uint256 fromIndex = 0;
        uint256 toIndex = 3;
        uint256 amount = 400e18;

        address from = univ2Factory.getPair(weth, dai);
        address fromUnderlying = dai;

        address to = univ2Factory.getPair(weth, wbtc);
        address toUnderlying = wbtc;

        _test_uni_uni_swap(
            fromIndex,
            toIndex,
            amount,
            abi.encode(from, fromUnderlying, to, toUnderlying)
        );
    }

    function test_jar_converter_uni_uni_1_0() public {
        uint256 fromIndex = 1;
        uint256 toIndex = 0;
        uint256 amount = 400e6;

        address from = univ2Factory.getPair(weth, usdc);
        address fromUnderlying = usdc;

        address to = univ2Factory.getPair(weth, dai);
        address toUnderlying = dai;

        _test_uni_uni_swap(
            fromIndex,
            toIndex,
            amount,
            abi.encode(from, fromUnderlying, to, toUnderlying)
        );
    }

    function test_jar_converter_uni_uni_1_2() public {
        uint256 fromIndex = 1;
        uint256 toIndex = 2;
        uint256 amount = 400e6;

        address from = univ2Factory.getPair(weth, usdc);
        address fromUnderlying = usdc;

        address to = univ2Factory.getPair(weth, usdt);
        address toUnderlying = usdt;

        _test_uni_uni_swap(
            fromIndex,
            toIndex,
            amount,
            abi.encode(from, fromUnderlying, to, toUnderlying)
        );
    }

    function test_jar_converter_uni_uni_1_3() public {
        uint256 fromIndex = 1;
        uint256 toIndex = 3;
        uint256 amount = 400e6;

        address from = univ2Factory.getPair(weth, usdc);
        address fromUnderlying = usdc;

        address to = univ2Factory.getPair(weth, wbtc);
        address toUnderlying = wbtc;

        _test_uni_uni_swap(
            fromIndex,
            toIndex,
            amount,
            abi.encode(from, fromUnderlying, to, toUnderlying)
        );
    }

    function test_jar_converter_uni_uni_2_0() public {
        uint256 fromIndex = 2;
        uint256 toIndex = 0;
        uint256 amount = 400e6;

        address from = univ2Factory.getPair(weth, usdt);
        address fromUnderlying = usdt;

        address to = univ2Factory.getPair(weth, dai);
        address toUnderlying = dai;

        _test_uni_uni_swap(
            fromIndex,
            toIndex,
            amount,
            abi.encode(from, fromUnderlying, to, toUnderlying)
        );
    }

    function test_jar_converter_uni_uni_2_1() public {
        uint256 fromIndex = 2;
        uint256 toIndex = 1;
        uint256 amount = 400e6;

        address from = univ2Factory.getPair(weth, usdt);
        address fromUnderlying = usdt;

        address to = univ2Factory.getPair(weth, usdc);
        address toUnderlying = usdc;

        _test_uni_uni_swap(
            fromIndex,
            toIndex,
            amount,
            abi.encode(from, fromUnderlying, to, toUnderlying)
        );
    }

    function test_jar_converter_uni_uni_2_3() public {
        uint256 fromIndex = 2;
        uint256 toIndex = 3;
        uint256 amount = 400e6;

        address from = univ2Factory.getPair(weth, usdt);
        address fromUnderlying = usdt;

        address to = univ2Factory.getPair(weth, wbtc);
        address toUnderlying = wbtc;

        _test_uni_uni_swap(
            fromIndex,
            toIndex,
            amount,
            abi.encode(from, fromUnderlying, to, toUnderlying)
        );
    }

    function test_jar_converter_uni_uni_3_0() public {
        uint256 fromIndex = 3;
        uint256 toIndex = 0;
        uint256 amount = 4e6;

        address from = univ2Factory.getPair(weth, wbtc);
        address fromUnderlying = wbtc;

        address to = univ2Factory.getPair(weth, dai);
        address toUnderlying = dai;

        _test_uni_uni_swap(
            fromIndex,
            toIndex,
            amount,
            abi.encode(from, fromUnderlying, to, toUnderlying)
        );
    }

    function test_jar_converter_uni_uni_3_1() public {
        uint256 fromIndex = 3;
        uint256 toIndex = 1;
        uint256 amount = 4e6;

        address from = univ2Factory.getPair(weth, wbtc);
        address fromUnderlying = wbtc;

        address to = univ2Factory.getPair(weth, usdc);
        address toUnderlying = usdc;

        _test_uni_uni_swap(
            fromIndex,
            toIndex,
            amount,
            abi.encode(from, fromUnderlying, to, toUnderlying)
        );
    }

    function test_jar_converter_uni_uni_3_2() public {
        uint256 fromIndex = 3;
        uint256 toIndex = 2;
        uint256 amount = 4e6;

        address from = univ2Factory.getPair(weth, wbtc);
        address fromUnderlying = wbtc;

        address to = univ2Factory.getPair(weth, usdt);
        address toUnderlying = usdt;

        _test_uni_uni_swap(
            fromIndex,
            toIndex,
            amount,
            abi.encode(from, fromUnderlying, to, toUnderlying)
        );
    }
}
