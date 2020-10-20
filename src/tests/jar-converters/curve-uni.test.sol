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

import "../../jar-converters/curve-uni-converter.sol";

import "../../strategies/uniswapv2/strategy-uni-eth-dai-lp-v3_1.sol";
import "../../strategies/uniswapv2/strategy-uni-eth-usdt-lp-v3_1.sol";
import "../../strategies/uniswapv2/strategy-uni-eth-usdc-lp-v3_1.sol";
import "../../strategies/uniswapv2/strategy-uni-eth-wbtc-lp-v1.sol";

import "../../strategies/curve/strategy-curve-scrv-v3_1.sol";
import "../../strategies/curve/strategy-curve-rencrv-v1.sol";
import "../../strategies/curve/strategy-curve-3crv-v1.sol";

contract StrategyCurveUniJarSwapTest is DSTestDefiBase {
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

    CurveUniJarConverter curveUniJarConverter;

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
                new StrategyCurve3CRVv1(
                    governance,
                    strategist,
                    address(controller),
                    timelock
                )
            )
        );
        curveStrategies[1] = IStrategy(
            address(
                new StrategyCurveSCRVv3_1(
                    governance,
                    strategist,
                    address(controller),
                    timelock
                )
            )
        );
        curveStrategies[2] = IStrategy(
            address(
                new StrategyCurveRenCRVv1(
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

        curveUniJarConverter = new CurveUniJarConverter();

        controller.approveJarConverter(address(curveUniJarConverter));

        hevm.warp(startTime);
    }

    function _getCurveLP(address curve, uint256 amount) internal {
        if (curve == ren_pool) {
            _getERC20(wbtc, amount);
            uint256 _wbtc = IERC20(wbtc).balanceOf(address(this));
            IERC20(wbtc).approve(curve, _wbtc);

            uint256[2] memory liquidity;
            liquidity[1] = _wbtc;
            ICurveFi_2(curve).add_liquidity(liquidity, 0);
        } else {
            _getERC20(dai, amount);
            uint256 _dai = IERC20(dai).balanceOf(address(this));
            IERC20(dai).approve(curve, _dai);

            if (curve == three_pool) {
                uint256[3] memory liquidity;
                liquidity[0] = _dai;
                ICurveFi_3(curve).add_liquidity(liquidity, 0);
            } else {
                uint256[4] memory liquidity;
                liquidity[0] = _dai;
                ICurveFi_4(curve).add_liquidity(liquidity, 0);
            }
        }
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

    function _test_curve_uni_swap(bytes memory _data) internal {
        TestParams memory params = abi.decode(_data, (TestParams));

        // Deposit into PickleJars
        address from = address(curvePickleJars[params.fromIndex].token());

        _getCurveLP(params.curvePool, params.fromUnderlyingAmount);

        uint256 _from = IERC20(from).balanceOf(address(this));
        IERC20(from).approve(address(curvePickleJars[params.fromIndex]), _from);
        curvePickleJars[params.fromIndex].deposit(_from);
        curvePickleJars[params.fromIndex].earn();

        // Swap!
        uint256 _fromPickleJar = IERC20(
            address(curvePickleJars[params.fromIndex])
        )
            .balanceOf(address(this));
        IERC20(address(curvePickleJars[params.fromIndex])).approve(
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
                address(curvePickleJars[params.fromIndex]),
                address(uniPickleJars[params.toIndex]),
                _fromPickleJar,
                uint256(-1), // Min receive amount
                address(curveUniJarConverter),
                data
            )
         {
            revert("min-amount-should-fail");
        } catch {}

        uint256 _beforeTo = IERC20(address(uniPickleJars[params.toIndex]))
            .balanceOf(address(this));
        uint256 _beforeFrom = IERC20(address(curvePickleJars[params.fromIndex]))
            .balanceOf(address(this));
        uint256 _beforeDev = IERC20(from).balanceOf(devfund);
        uint256 _beforeTreasury = IERC20(from).balanceOf(treasury);

        temp = controller.swapExactJarForJar(
            address(curvePickleJars[params.fromIndex]),
            address(uniPickleJars[params.toIndex]),
            _fromPickleJar,
            0, // Min receive amount
            address(curveUniJarConverter),
            data
        );

        uint256 _afterTo = IERC20(address(uniPickleJars[params.toIndex]))
            .balanceOf(address(this));
        uint256 _afterFrom = IERC20(address(curvePickleJars[params.fromIndex]))
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
        assertTrue(_afterFrom < _beforeFrom);
        assertTrue(_afterTo > _beforeTo);
        assertTrue(_afterTo.sub(_beforeTo) > 0);
        assertEq(_afterTo.sub(_beforeTo), temp);
        assertEq(_afterFrom, 0);
    }

    // Tests
    function test_jar_converter_curve_uni_0_0() public {
        uint256 fromIndex = 0;
        uint256 toIndex = 0;

        address fromUnderlying = dai;
        uint256 fromUnderlyingAmount = 400e18;

        address curvePool = three_pool;
        bytes4 curveFunctionSig = bytes4(
            keccak256(bytes("remove_liquidity(uint256,uint256[3])"))
        );
        uint256 curvePoolSize = uint256(3);
        uint256 curveUnderlyingIndex = uint256(0);

        address toWant = univ2Factory.getPair(weth, dai);
        address toUnderlying = dai;

        _test_curve_uni_swap(
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
    }

    function test_jar_converter_curve_uni_0_1() public {
        uint256 fromIndex = 0;
        uint256 toIndex = 1;

        address fromUnderlying = dai;
        uint256 fromUnderlyingAmount = 400e18;

        address curvePool = three_pool;
        bytes4 curveFunctionSig = bytes4(
            keccak256(bytes("remove_liquidity(uint256,uint256[3])"))
        );
        uint256 curvePoolSize = uint256(3);
        uint256 curveUnderlyingIndex = uint256(0);

        address toWant = univ2Factory.getPair(weth, usdc);
        address toUnderlying = usdc;

        _test_curve_uni_swap(
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
    }

    function test_jar_converter_curve_uni_0_2() public {
        uint256 fromIndex = 0;
        uint256 toIndex = 2;

        address fromUnderlying = dai;
        uint256 fromUnderlyingAmount = 400e18;

        address curvePool = three_pool;
        bytes4 curveFunctionSig = bytes4(
            keccak256(bytes("remove_liquidity(uint256,uint256[3])"))
        );
        uint256 curvePoolSize = uint256(3);
        uint256 curveUnderlyingIndex = uint256(0);

        address toWant = univ2Factory.getPair(weth, usdt);
        address toUnderlying = usdt;

        _test_curve_uni_swap(
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
    }

    function test_jar_converter_curve_uni_0_3() public {
        uint256 fromIndex = 0;
        uint256 toIndex = 3;

        address fromUnderlying = dai;
        uint256 fromUnderlyingAmount = 400e18;

        address curvePool = three_pool;
        bytes4 curveFunctionSig = bytes4(
            keccak256(bytes("remove_liquidity(uint256,uint256[3])"))
        );
        uint256 curvePoolSize = uint256(3);
        uint256 curveUnderlyingIndex = uint256(0);

        address toWant = univ2Factory.getPair(weth, wbtc);
        address toUnderlying = wbtc;

        _test_curve_uni_swap(
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
    }

    function test_jar_converter_curve_uni_1_0() public {
        uint256 fromIndex = 1;
        uint256 toIndex = 0;

        address fromUnderlying = dai;
        uint256 fromUnderlyingAmount = 400e18;

        address curvePool = susdv2_pool;
        bytes4 curveFunctionSig = bytes4(
            keccak256(bytes("remove_liquidity(uint256,uint256[4])"))
        );
        uint256 curvePoolSize = uint256(4);
        uint256 curveUnderlyingIndex = uint256(0);

        address toWant = univ2Factory.getPair(weth, dai);
        address toUnderlying = dai;

        _test_curve_uni_swap(
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
    }

    function test_jar_converter_curve_uni_1_1() public {
        uint256 fromIndex = 1;
        uint256 toIndex = 1;

        address fromUnderlying = dai;
        uint256 fromUnderlyingAmount = 400e18;

        address curvePool = susdv2_pool;
        bytes4 curveFunctionSig = bytes4(
            keccak256(bytes("remove_liquidity(uint256,uint256[4])"))
        );
        uint256 curvePoolSize = uint256(4);
        uint256 curveUnderlyingIndex = uint256(0);

        address toWant = univ2Factory.getPair(weth, usdc);
        address toUnderlying = usdc;

        _test_curve_uni_swap(
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
    }

    function test_jar_converter_curve_uni_1_2() public {
        uint256 fromIndex = 1;
        uint256 toIndex = 2;

        address fromUnderlying = dai;
        uint256 fromUnderlyingAmount = 400e18;

        address curvePool = susdv2_pool;
        bytes4 curveFunctionSig = bytes4(
            keccak256(bytes("remove_liquidity(uint256,uint256[4])"))
        );
        uint256 curvePoolSize = uint256(4);
        uint256 curveUnderlyingIndex = uint256(0);

        address toWant = univ2Factory.getPair(weth, usdt);
        address toUnderlying = usdt;

        _test_curve_uni_swap(
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
    }

    function test_jar_converter_curve_uni_1_3() public {
        uint256 fromIndex = 1;
        uint256 toIndex = 3;

        address fromUnderlying = dai;
        uint256 fromUnderlyingAmount = 400e18;

        address curvePool = susdv2_pool;
        bytes4 curveFunctionSig = bytes4(
            keccak256(bytes("remove_liquidity(uint256,uint256[4])"))
        );
        uint256 curvePoolSize = uint256(4);
        uint256 curveUnderlyingIndex = uint256(0);

        address toWant = univ2Factory.getPair(weth, wbtc);
        address toUnderlying = wbtc;

        _test_curve_uni_swap(
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
    }

    function test_jar_converter_curve_uni_2_0() public {
        uint256 fromIndex = 2;
        uint256 toIndex = 0;

        address fromUnderlying = wbtc;
        uint256 fromUnderlyingAmount = 4e6; // 0.04 BTC

        address curvePool = ren_pool;
        bytes4 curveFunctionSig = bytes4(
            keccak256(bytes("remove_liquidity(uint256,uint256[2])"))
        );
        uint256 curvePoolSize = uint256(2);
        uint256 curveUnderlyingIndex = uint256(0);

        address toWant = univ2Factory.getPair(weth, dai);
        address toUnderlying = dai;

        _test_curve_uni_swap(
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
    }

    function test_jar_converter_curve_uni_2_1() public {
        uint256 fromIndex = 2;
        uint256 toIndex = 1;

        address fromUnderlying = wbtc;
        uint256 fromUnderlyingAmount = 4e6; // 0.04 BTC

        address curvePool = ren_pool;
        bytes4 curveFunctionSig = bytes4(
            keccak256(bytes("remove_liquidity(uint256,uint256[2])"))
        );
        uint256 curvePoolSize = uint256(2);
        uint256 curveUnderlyingIndex = uint256(0);

        address toWant = univ2Factory.getPair(weth, usdc);
        address toUnderlying = usdc;

        _test_curve_uni_swap(
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
    }

    function test_jar_converter_curve_uni_2_2() public {
        uint256 fromIndex = 2;
        uint256 toIndex = 2;

        address fromUnderlying = wbtc;
        uint256 fromUnderlyingAmount = 4e6; // 0.04 BTC

        address curvePool = ren_pool;
        bytes4 curveFunctionSig = bytes4(
            keccak256(bytes("remove_liquidity(uint256,uint256[2])"))
        );
        uint256 curvePoolSize = uint256(2);
        uint256 curveUnderlyingIndex = uint256(0);

        address toWant = univ2Factory.getPair(weth, usdt);
        address toUnderlying = usdt;

        _test_curve_uni_swap(
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
    }

    function test_jar_converter_curve_uni_2_3() public {
        uint256 fromIndex = 2;
        uint256 toIndex = 3;

        address fromUnderlying = wbtc;
        uint256 fromUnderlyingAmount = 4e6; // 0.04 BTC

        address curvePool = ren_pool;
        bytes4 curveFunctionSig = bytes4(
            keccak256(bytes("remove_liquidity(uint256,uint256[2])"))
        );
        uint256 curvePoolSize = uint256(2);
        uint256 curveUnderlyingIndex = uint256(0);

        address toWant = univ2Factory.getPair(weth, wbtc);
        address toUnderlying = wbtc;

        _test_curve_uni_swap(
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
    }
}
