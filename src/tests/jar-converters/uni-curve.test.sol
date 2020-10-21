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

import "../../jar-converters/uni-curve-converter.sol";

import "../../strategies/uniswapv2/strategy-uni-eth-dai-lp-v4.sol";
import "../../strategies/uniswapv2/strategy-uni-eth-usdt-lp-v4.sol";
import "../../strategies/uniswapv2/strategy-uni-eth-usdc-lp-v4.sol";
import "../../strategies/uniswapv2/strategy-uni-eth-wbtc-lp-v2.sol";

import "../../strategies/curve/strategy-curve-scrv-v3_2.sol";
import "../../strategies/curve/strategy-curve-rencrv-v2.sol";
import "../../strategies/curve/strategy-curve-3crv-v2.sol";

contract StrategyUniCurveJarSwapTest is DSTestDefiBase {
    address governance;
    address strategist;
    address devfund;
    address treasury;
    address timelock;

    IStrategy[] curveStrategies;
    IStrategy[] uniStrategies;

    PickleJar[] curvePickleJars;
    PickleJar[] uniPickleJars;

    ControllerV4 controller;

    UniCurveJarConverter uniCurveJarConverter;

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

        // Curve Strategies
        curveStrategies = new IStrategy[](3);
        curvePickleJars = new PickleJar[](curveStrategies.length);
        curveStrategies[0] = IStrategy(
            address(
                new StrategyCurve3CRVv2(
                    governance,
                    strategist,
                    address(controller),
                    timelock
                )
            )
        );
        curveStrategies[1] = IStrategy(
            address(
                new StrategyCurveSCRVv3_2(
                    governance,
                    strategist,
                    address(controller),
                    timelock
                )
            )
        );
        curveStrategies[2] = IStrategy(
            address(
                new StrategyCurveRenCRVv2(
                    governance,
                    strategist,
                    address(controller),
                    timelock
                )
            )
        );

        // Create PICKLE Jars
        for (uint256 i = 0; i < curvePickleJars.length; i++) {
            curvePickleJars[i] = new PickleJar(
                curveStrategies[i].want(),
                governance,
                timelock,
                address(controller)
            );

            controller.setJar(
                curveStrategies[i].want(),
                address(curvePickleJars[i])
            );
            controller.approveStrategy(
                curveStrategies[i].want(),
                address(curveStrategies[i])
            );
            controller.setStrategy(
                curveStrategies[i].want(),
                address(curveStrategies[i])
            );
        }

        // Uni strategies
        uniStrategies = new IStrategy[](4);
        uniPickleJars = new PickleJar[](uniStrategies.length);
        uniStrategies[0] = IStrategy(
            address(
                new StrategyUniEthDaiLpV4(
                    governance,
                    strategist,
                    address(controller),
                    timelock
                )
            )
        );
        uniStrategies[1] = IStrategy(
            address(
                new StrategyUniEthUsdcLpV4(
                    governance,
                    strategist,
                    address(controller),
                    timelock
                )
            )
        );
        uniStrategies[2] = IStrategy(
            address(
                new StrategyUniEthUsdtLpV4(
                    governance,
                    strategist,
                    address(controller),
                    timelock
                )
            )
        );
        uniStrategies[3] = IStrategy(
            address(
                new StrategyUniEthWBtcLpV2(
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

        uniCurveJarConverter = new UniCurveJarConverter();

        controller.approveJarConverter(address(uniCurveJarConverter));

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
        uint256 fromIndex;
        uint256 toIndex;
        address fromUnderlying;
        uint256 fromUnderlyingAmount;
        address toWant;
        address toUnderlying;
        address curvePool;
        bytes4 curveFunctionSig;
        uint256 curvePoolSize;
        uint256 curveUnderlyingIndex;
    }

    // Some post swap checks
    // Checks if there's any leftover funds in the converter contract
    function _post_swap_check(uint256 fromIndex, uint256 toIndex)
        internal
    {
        IERC20 token0 = uniPickleJars[fromIndex].token();
        IERC20 token1 = curvePickleJars[toIndex].token();

        // 100 WEI in DUST
        uint256 MAX_DUST = 100;

        // No funds left behind
        assertEq(uniPickleJars[fromIndex].balanceOf(address(controller)), 0);
        assertEq(curvePickleJars[toIndex].balanceOf(address(controller)), 0);
        assertTrue(token0.balanceOf(address(controller)) < MAX_DUST);
        assertTrue(token1.balanceOf(address(controller)) < MAX_DUST);
        assertEq(token0.balanceOf(address(uniCurveJarConverter)), 0);
        assertEq(token1.balanceOf(address(uniCurveJarConverter)), 0);

        // Make sure only controller can call 'withdrawForSwap' 
        try uniStrategies[fromIndex].withdrawForSwap(0) {
            revert("!withdraw-for-swap-only-controller");
        } catch {}
    }

    function _test_uni_curve_swap(bytes memory _data) internal {
        TestParams memory params = abi.decode(_data, (TestParams));

        // Deposit into PickleJars
        address from = address(uniPickleJars[params.fromIndex].token());

        _getUniLP(from, 1e18, params.fromUnderlyingAmount);

        uint256 _from = IERC20(from).balanceOf(address(this));
        IERC20(from).approve(address(uniPickleJars[params.fromIndex]), _from);
        uniPickleJars[params.fromIndex].deposit(_from);
        uniPickleJars[params.fromIndex].earn();

        // Swap!
        uint256 _fromPickleJar = IERC20(
            address(uniPickleJars[params.fromIndex])
        )
            .balanceOf(address(this));
        IERC20(address(uniPickleJars[params.fromIndex])).approve(
            address(controller),
            _fromPickleJar
        );

        bytes memory data = abi.encode(
            params.curvePool,
            params.curveFunctionSig,
            params.curvePoolSize,
            params.curveUnderlyingIndex,
            from,
            params.fromUnderlying,
            params.toWant,
            params.toUnderlying
        );

        // Check minimum amount
        try
            controller.swapExactJarForJar(
                address(uniPickleJars[params.fromIndex]),
                address(curvePickleJars[params.toIndex]),
                _fromPickleJar,
                uint256(-1), // Min receive amount
                address(uniCurveJarConverter),
                data
            )
         {
            revert("min-amount-should-fail");
        } catch {}

        uint256 _beforeTo = IERC20(address(curvePickleJars[params.toIndex]))
            .balanceOf(address(this));
        uint256 _beforeFrom = IERC20(address(uniPickleJars[params.fromIndex]))
            .balanceOf(address(this));
        uint256 _beforeDev = IERC20(from).balanceOf(devfund);
        uint256 _beforeTreasury = IERC20(from).balanceOf(treasury);

        temp = controller.swapExactJarForJar(
            address(uniPickleJars[params.fromIndex]),
            address(curvePickleJars[params.toIndex]),
            _fromPickleJar,
            0, // Min receive amount
            address(uniCurveJarConverter),
            data
        );

        uint256 _afterTo = IERC20(address(curvePickleJars[params.toIndex]))
            .balanceOf(address(this));
        uint256 _afterFrom = IERC20(address(uniPickleJars[params.fromIndex]))
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
    function test_jar_converter_uni_curve_0_0() public {
        uint256 fromIndex = 0;
        uint256 toIndex = 0;
        address fromUnderlying = dai;
        uint256 fromUnderlyingAmount = 400e18;
        address toWant = three_crv;
        address toUnderlying = dai;
        address curvePool = three_pool;
        bytes4 curveFunctionSig = bytes4(
            keccak256(bytes("add_liquidity(uint256[3],uint256)"))
        );

        uint256 curvePoolSize = uint256(3);
        uint256 curveUnderlyingIndex = uint256(0);

        _test_uni_curve_swap(
            abi.encode(
                fromIndex,
                toIndex,
                fromUnderlying,
                fromUnderlyingAmount,
                toWant,
                toUnderlying,
                curvePool,
                curveFunctionSig,
                curvePoolSize,
                curveUnderlyingIndex
            )
        );
        _post_swap_check(fromIndex, toIndex);
    }

    function test_jar_converter_uni_curve_0_1() public {
        uint256 fromIndex = 0;
        uint256 toIndex = 1;
        address fromUnderlying = dai;
        uint256 fromUnderlyingAmount = 400e18;
        address toWant = scrv;
        address toUnderlying = dai;
        address curvePool = susdv2_pool;
        bytes4 curveFunctionSig = bytes4(
            keccak256(bytes("add_liquidity(uint256[4],uint256)"))
        );

        uint256 curvePoolSize = uint256(4);
        uint256 curveUnderlyingIndex = uint256(0);

        _test_uni_curve_swap(
            abi.encode(
                fromIndex,
                toIndex,
                fromUnderlying,
                fromUnderlyingAmount,
                toWant,
                toUnderlying,
                curvePool,
                curveFunctionSig,
                curvePoolSize,
                curveUnderlyingIndex
            )
        );
        _post_swap_check(fromIndex, toIndex);
    }

    function test_jar_converter_uni_curve_0_2() public {
        uint256 fromIndex = 0;
        uint256 toIndex = 2;
        address fromUnderlying = dai;
        uint256 fromUnderlyingAmount = 400e18;
        address toWant = ren_crv;
        address toUnderlying = wbtc;
        address curvePool = ren_pool;
        bytes4 curveFunctionSig = bytes4(
            keccak256(bytes("add_liquidity(uint256[2],uint256)"))
        );
        uint256 curvePoolSize = uint256(2);
        uint256 curveUnderlyingIndex = uint256(1);

        _test_uni_curve_swap(
            abi.encode(
                fromIndex,
                toIndex,
                fromUnderlying,
                fromUnderlyingAmount,
                toWant,
                toUnderlying,
                curvePool,
                curveFunctionSig,
                curvePoolSize,
                curveUnderlyingIndex
            )
        );
        _post_swap_check(fromIndex, toIndex);
    }

    function test_jar_converter_uni_curve_1_0() public {
        uint256 fromIndex = 1;
        uint256 toIndex = 0;
        address fromUnderlying = usdc;
        uint256 fromUnderlyingAmount = 400e6;
        address toWant = three_crv;
        address toUnderlying = dai;
        address curvePool = three_pool;
        bytes4 curveFunctionSig = bytes4(
            keccak256(bytes("add_liquidity(uint256[3],uint256)"))
        );

        uint256 curvePoolSize = uint256(3);
        uint256 curveUnderlyingIndex = uint256(0);

        _test_uni_curve_swap(
            abi.encode(
                fromIndex,
                toIndex,
                fromUnderlying,
                fromUnderlyingAmount,
                toWant,
                toUnderlying,
                curvePool,
                curveFunctionSig,
                curvePoolSize,
                curveUnderlyingIndex
            )
        );
        _post_swap_check(fromIndex, toIndex);
    }

    function test_jar_converter_uni_curve_1_1() public {
        uint256 fromIndex = 1;
        uint256 toIndex = 1;
        address fromUnderlying = usdc;
        uint256 fromUnderlyingAmount = 400e6;
        address toWant = scrv;
        address toUnderlying = dai;
        address curvePool = susdv2_pool;
        bytes4 curveFunctionSig = bytes4(
            keccak256(bytes("add_liquidity(uint256[4],uint256)"))
        );

        uint256 curvePoolSize = uint256(4);
        uint256 curveUnderlyingIndex = uint256(0);

        _test_uni_curve_swap(
            abi.encode(
                fromIndex,
                toIndex,
                fromUnderlying,
                fromUnderlyingAmount,
                toWant,
                toUnderlying,
                curvePool,
                curveFunctionSig,
                curvePoolSize,
                curveUnderlyingIndex
            )
        );
        _post_swap_check(fromIndex, toIndex);
    }

    function test_jar_converter_uni_curve_1_2() public {
        uint256 fromIndex = 1;
        uint256 toIndex = 2;
        address fromUnderlying = usdc;
        uint256 fromUnderlyingAmount = 400e6;
        address toWant = ren_crv;
        address toUnderlying = wbtc;
        address curvePool = ren_pool;
        bytes4 curveFunctionSig = bytes4(
            keccak256(bytes("add_liquidity(uint256[2],uint256)"))
        );
        uint256 curvePoolSize = uint256(2);
        uint256 curveUnderlyingIndex = uint256(1);

        _test_uni_curve_swap(
            abi.encode(
                fromIndex,
                toIndex,
                fromUnderlying,
                fromUnderlyingAmount,
                toWant,
                toUnderlying,
                curvePool,
                curveFunctionSig,
                curvePoolSize,
                curveUnderlyingIndex
            )
        );
        _post_swap_check(fromIndex, toIndex);
    }

    function test_jar_converter_uni_curve_2_0() public {
        uint256 fromIndex = 2;
        uint256 toIndex = 0;
        address fromUnderlying = usdt;
        uint256 fromUnderlyingAmount = 400e6;
        address toWant = three_crv;
        address toUnderlying = dai;
        address curvePool = three_pool;
        bytes4 curveFunctionSig = bytes4(
            keccak256(bytes("add_liquidity(uint256[3],uint256)"))
        );

        uint256 curvePoolSize = uint256(3);
        uint256 curveUnderlyingIndex = uint256(0);

        _test_uni_curve_swap(
            abi.encode(
                fromIndex,
                toIndex,
                fromUnderlying,
                fromUnderlyingAmount,
                toWant,
                toUnderlying,
                curvePool,
                curveFunctionSig,
                curvePoolSize,
                curveUnderlyingIndex
            )
        );
        _post_swap_check(fromIndex, toIndex);
    }

    function test_jar_converter_uni_curve_2_1() public {
        uint256 fromIndex = 2;
        uint256 toIndex = 1;
        address fromUnderlying = usdt;
        uint256 fromUnderlyingAmount = 400e6;
        address toWant = scrv;
        address toUnderlying = dai;
        address curvePool = susdv2_pool;
        bytes4 curveFunctionSig = bytes4(
            keccak256(bytes("add_liquidity(uint256[4],uint256)"))
        );

        uint256 curvePoolSize = uint256(4);
        uint256 curveUnderlyingIndex = uint256(0);

        _test_uni_curve_swap(
            abi.encode(
                fromIndex,
                toIndex,
                fromUnderlying,
                fromUnderlyingAmount,
                toWant,
                toUnderlying,
                curvePool,
                curveFunctionSig,
                curvePoolSize,
                curveUnderlyingIndex
            )
        );
        _post_swap_check(fromIndex, toIndex);
    }

    function test_jar_converter_uni_curve_2_2() public {
        uint256 fromIndex = 2;
        uint256 toIndex = 2;
        address fromUnderlying = usdt;
        uint256 fromUnderlyingAmount = 400e6;
        address toWant = ren_crv;
        address toUnderlying = wbtc;
        address curvePool = ren_pool;
        bytes4 curveFunctionSig = bytes4(
            keccak256(bytes("add_liquidity(uint256[2],uint256)"))
        );
        uint256 curvePoolSize = uint256(2);
        uint256 curveUnderlyingIndex = uint256(1);

        _test_uni_curve_swap(
            abi.encode(
                fromIndex,
                toIndex,
                fromUnderlying,
                fromUnderlyingAmount,
                toWant,
                toUnderlying,
                curvePool,
                curveFunctionSig,
                curvePoolSize,
                curveUnderlyingIndex
            )
        );
        _post_swap_check(fromIndex, toIndex);
    }

    function test_jar_converter_uni_curve_3_0() public {
        uint256 fromIndex = 3;
        uint256 toIndex = 0;
        address fromUnderlying = wbtc;
        uint256 fromUnderlyingAmount = 4e6; // 0.04 BTC
        address toWant = three_crv;
        address toUnderlying = dai;
        address curvePool = three_pool;
        bytes4 curveFunctionSig = bytes4(
            keccak256(bytes("add_liquidity(uint256[3],uint256)"))
        );

        uint256 curvePoolSize = uint256(3);
        uint256 curveUnderlyingIndex = uint256(0);

        _test_uni_curve_swap(
            abi.encode(
                fromIndex,
                toIndex,
                fromUnderlying,
                fromUnderlyingAmount,
                toWant,
                toUnderlying,
                curvePool,
                curveFunctionSig,
                curvePoolSize,
                curveUnderlyingIndex
            )
        );
        _post_swap_check(fromIndex, toIndex);
    }

    function test_jar_converter_uni_curve_3_1() public {
        uint256 fromIndex = 3;
        uint256 toIndex = 1;
        address fromUnderlying = wbtc;
        uint256 fromUnderlyingAmount = 4e6; // 0.04 BTC
        address toWant = scrv;
        address toUnderlying = dai;
        address curvePool = susdv2_pool;
        bytes4 curveFunctionSig = bytes4(
            keccak256(bytes("add_liquidity(uint256[4],uint256)"))
        );

        uint256 curvePoolSize = uint256(4);
        uint256 curveUnderlyingIndex = uint256(0);

        _test_uni_curve_swap(
            abi.encode(
                fromIndex,
                toIndex,
                fromUnderlying,
                fromUnderlyingAmount,
                toWant,
                toUnderlying,
                curvePool,
                curveFunctionSig,
                curvePoolSize,
                curveUnderlyingIndex
            )
        );
        _post_swap_check(fromIndex, toIndex);
    }

    function test_jar_converter_uni_curve_3_2() public {
        uint256 fromIndex = 3;
        uint256 toIndex = 2;
        address fromUnderlying = wbtc;
        uint256 fromUnderlyingAmount = 4e6; // 0.04 BTC
        address toWant = ren_crv;
        address toUnderlying = wbtc;
        address curvePool = ren_pool;
        bytes4 curveFunctionSig = bytes4(
            keccak256(bytes("add_liquidity(uint256[2],uint256)"))
        );
        uint256 curvePoolSize = uint256(2);
        uint256 curveUnderlyingIndex = uint256(1);

        _test_uni_curve_swap(
            abi.encode(
                fromIndex,
                toIndex,
                fromUnderlying,
                fromUnderlyingAmount,
                toWant,
                toUnderlying,
                curvePool,
                curveFunctionSig,
                curvePoolSize,
                curveUnderlyingIndex
            )
        );
        _post_swap_check(fromIndex, toIndex);
    }
}
