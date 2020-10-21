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

import "../../jar-converters/curve-curve-converter.sol";

import "../../strategies/curve/strategy-curve-scrv-v3_2.sol";
import "../../strategies/curve/strategy-curve-rencrv-v2.sol";
import "../../strategies/curve/strategy-curve-3crv-v2.sol";

contract StrategyCurveCurveJarSwapTest is DSTestDefiBase {
    address governance;
    address strategist;
    address devfund;
    address treasury;
    address timelock;

    IStrategy[] curveStrategies;

    PickleJar[] curvePickleJars;

    ControllerV4 controller;

    CurveCurveJarConverter curveCurveJarConverter;

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

        curveCurveJarConverter = new CurveCurveJarConverter();

        controller.approveJarConverter(address(curveCurveJarConverter));

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
        address fromUnderlying;
        address fromCurve;
        address fromCurveLP;
        bytes4 fromCurveFunctionSig;
        uint256 fromCurvePoolSize;
        uint256 fromCurveUnderlyingIndex;
        address toUnderlying;
        address toCurve;
        address toCurveLP;
        bytes4 toCurveFunctionSig;
        uint256 toCurvePoolSize;
        uint256 toCurveUnderlyingIndex;
    }

    // Some post swap checks
    // Checks if there's any leftover funds in the converter contract
    function _post_swap_check(uint256 fromIndex, uint256 toIndex) internal {
        IERC20 token0 = curvePickleJars[fromIndex].token();
        IERC20 token1 = curvePickleJars[toIndex].token();

        uint256 MAX_DUST = 10;

        // No funds left behind
        assertEq(curvePickleJars[fromIndex].balanceOf(address(controller)), 0);
        assertEq(curvePickleJars[toIndex].balanceOf(address(controller)), 0);
        assertTrue(token0.balanceOf(address(controller)) < MAX_DUST);
        assertTrue(token1.balanceOf(address(controller)) < MAX_DUST);
        assertEq(token0.balanceOf(address(curveCurveJarConverter)), 0);
        assertEq(token1.balanceOf(address(curveCurveJarConverter)), 0);

        // Make sure only controller can call 'withdrawForSwap'
        try curveStrategies[fromIndex].withdrawForSwap(0)  {
            revert("!withdraw-for-swap-only-controller");
        } catch {}
    }

    function _test_curve_curve_swap(
        uint256 fromIndex,
        uint256 toIndex,
        uint256 amount,
        bytes memory _data
    ) internal {
        TestParams memory params = abi.decode(_data, (TestParams));

        // Deposit into PickleJars
        address from = address(curvePickleJars[fromIndex].token());

        _getCurveLP(params.fromCurve, amount);

        uint256 _from = IERC20(from).balanceOf(address(this));
        IERC20(from).approve(address(curvePickleJars[fromIndex]), _from);
        curvePickleJars[fromIndex].deposit(_from);
        curvePickleJars[fromIndex].earn();

        // Swap!
        uint256 _fromPickleJar = IERC20(address(curvePickleJars[fromIndex]))
            .balanceOf(address(this));
        IERC20(address(curvePickleJars[fromIndex])).approve(
            address(controller),
            _fromPickleJar
        );

        bytes memory data = abi.encode(
            params.fromUnderlying,
            params.fromCurve,
            params.fromCurveLP,
            params.fromCurveFunctionSig,
            params.fromCurvePoolSize,
            params.fromCurveUnderlyingIndex,
            params.toUnderlying,
            params.toCurve,
            params.toCurveLP,
            params.toCurveFunctionSig,
            params.toCurvePoolSize,
            params.toCurveUnderlyingIndex
        );

        // Check minimum amount
        try
            controller.swapExactJarForJar(
                address(curvePickleJars[fromIndex]),
                address(curvePickleJars[toIndex]),
                _fromPickleJar,
                uint256(-1), // Min receive amount
                address(curveCurveJarConverter),
                data
            )
         {
            revert("min-amount-should-fail");
        } catch {}

        uint256 _beforeTo = IERC20(address(curvePickleJars[toIndex])).balanceOf(
            address(this)
        );
        uint256 _beforeFrom = IERC20(address(curvePickleJars[fromIndex]))
            .balanceOf(address(this));
        uint256 _beforeDev = IERC20(from).balanceOf(devfund);
        uint256 _beforeTreasury = IERC20(from).balanceOf(treasury);

        temp = controller.swapExactJarForJar(
            address(curvePickleJars[fromIndex]),
            address(curvePickleJars[toIndex]),
            _fromPickleJar,
            0, // Min receive amount
            address(curveCurveJarConverter),
            data
        );

        uint256 _afterTo = IERC20(address(curvePickleJars[toIndex])).balanceOf(
            address(this)
        );
        uint256 _afterFrom = IERC20(address(curvePickleJars[fromIndex]))
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
    function test_jar_converter_curve_curve_0_1() public {
        uint256 fromIndex = 0;
        uint256 toIndex = 1;
        uint256 fromUnderlyingAmount = 400e18;

        address fromUnderlying = dai;
        address fromCurvePool = three_pool;
        address fromCurveLP = three_crv;
        bytes4 fromCurveFunctionSig = bytes4(
            keccak256(bytes("remove_liquidity(uint256,uint256[3])"))
        );
        uint256 fromCurvePoolSize = uint256(3);
        uint256 fromCurveUnderlyingIndex = uint256(0);

        address toUnderlying = dai;
        address toCurvePool = susdv2_pool;
        address toCurveLP = scrv;
        bytes4 toCurveFunctionSig = bytes4(
            keccak256(bytes("add_liquidity(uint256[4],uint256)"))
        );
        uint256 toCurvePoolSize = uint256(4);
        uint256 toCurveUnderlyingIndex = uint256(0);

        _test_curve_curve_swap(
            fromIndex,
            toIndex,
            fromUnderlyingAmount,
            abi.encode(
                fromUnderlying,
                fromCurvePool,
                fromCurveLP,
                fromCurveFunctionSig,
                fromCurvePoolSize,
                fromCurveUnderlyingIndex,
                toUnderlying,
                toCurvePool,
                toCurveLP,
                toCurveFunctionSig,
                toCurvePoolSize,
                toCurveUnderlyingIndex
            )
        );
        _post_swap_check(fromIndex, toIndex);
    }

    function test_jar_converter_curve_curve_0_2() public {
        uint256 fromIndex = 0;
        uint256 toIndex = 2;
        uint256 fromUnderlyingAmount = 400e18;

        address fromUnderlying = dai;
        address fromCurvePool = three_pool;
        address fromCurveLP = three_crv;
        bytes4 fromCurveFunctionSig = bytes4(
            keccak256(bytes("remove_liquidity(uint256,uint256[3])"))
        );
        uint256 fromCurvePoolSize = uint256(3);
        uint256 fromCurveUnderlyingIndex = uint256(0);

        address toUnderlying = wbtc;
        address toCurvePool = ren_pool;
        address toCurveLP = ren_crv;
        bytes4 toCurveFunctionSig = bytes4(
            keccak256(bytes("add_liquidity(uint256[2],uint256)"))
        );
        uint256 toCurvePoolSize = uint256(2);
        uint256 toCurveUnderlyingIndex = uint256(1);

        _test_curve_curve_swap(
            fromIndex,
            toIndex,
            fromUnderlyingAmount,
            abi.encode(
                fromUnderlying,
                fromCurvePool,
                fromCurveLP,
                fromCurveFunctionSig,
                fromCurvePoolSize,
                fromCurveUnderlyingIndex,
                toUnderlying,
                toCurvePool,
                toCurveLP,
                toCurveFunctionSig,
                toCurvePoolSize,
                toCurveUnderlyingIndex
            )
        );
        _post_swap_check(fromIndex, toIndex);
    }

    function test_jar_converter_curve_curve_1_0() public {
        uint256 fromIndex = 1;
        uint256 toIndex = 0;
        uint256 fromUnderlyingAmount = 400e18;

        address fromUnderlying = dai;
        address fromCurvePool = susdv2_pool;
        address fromCurveLP = scrv;
        bytes4 fromCurveFunctionSig = bytes4(
            keccak256(bytes("remove_liquidity(uint256,uint256[4])"))
        );
        uint256 fromCurvePoolSize = uint256(4);
        uint256 fromCurveUnderlyingIndex = uint256(0);

        address toUnderlying = dai;
        address toCurvePool = three_pool;
        address toCurveLP = three_crv;
        bytes4 toCurveFunctionSig = bytes4(
            keccak256(bytes("add_liquidity(uint256[3],uint256)"))
        );
        uint256 toCurvePoolSize = uint256(3);
        uint256 toCurveUnderlyingIndex = uint256(0);

        _test_curve_curve_swap(
            fromIndex,
            toIndex,
            fromUnderlyingAmount,
            abi.encode(
                fromUnderlying,
                fromCurvePool,
                fromCurveLP,
                fromCurveFunctionSig,
                fromCurvePoolSize,
                fromCurveUnderlyingIndex,
                toUnderlying,
                toCurvePool,
                toCurveLP,
                toCurveFunctionSig,
                toCurvePoolSize,
                toCurveUnderlyingIndex
            )
        );
        _post_swap_check(fromIndex, toIndex);
    }

    function test_jar_converter_curve_curve_1_2() public {
        uint256 fromIndex = 1;
        uint256 toIndex = 2;
        uint256 fromUnderlyingAmount = 400e18;

        address fromUnderlying = dai;
        address fromCurvePool = susdv2_pool;
        address fromCurveLP = scrv;
        bytes4 fromCurveFunctionSig = bytes4(
            keccak256(bytes("remove_liquidity(uint256,uint256[4])"))
        );
        uint256 fromCurvePoolSize = uint256(4);
        uint256 fromCurveUnderlyingIndex = uint256(0);

        address toUnderlying = wbtc;
        address toCurvePool = ren_pool;
        address toCurveLP = ren_crv;
        bytes4 toCurveFunctionSig = bytes4(
            keccak256(bytes("add_liquidity(uint256[2],uint256)"))
        );
        uint256 toCurvePoolSize = uint256(2);
        uint256 toCurveUnderlyingIndex = uint256(1);

        _test_curve_curve_swap(
            fromIndex,
            toIndex,
            fromUnderlyingAmount,
            abi.encode(
                fromUnderlying,
                fromCurvePool,
                fromCurveLP,
                fromCurveFunctionSig,
                fromCurvePoolSize,
                fromCurveUnderlyingIndex,
                toUnderlying,
                toCurvePool,
                toCurveLP,
                toCurveFunctionSig,
                toCurvePoolSize,
                toCurveUnderlyingIndex
            )
        );
        _post_swap_check(fromIndex, toIndex);
    }

    function test_jar_converter_curve_curve_2_0() public {
        uint256 fromIndex = 2;
        uint256 toIndex = 0;
        uint256 fromUnderlyingAmount = 4e6;

        address fromUnderlying = wbtc;
        address fromCurvePool = ren_pool;
        address fromCurveLP = ren_crv;
        bytes4 fromCurveFunctionSig = bytes4(
            keccak256(bytes("remove_liquidity(uint256,uint256[2])"))
        );
        uint256 fromCurvePoolSize = uint256(2);
        uint256 fromCurveUnderlyingIndex = uint256(1);

        address toUnderlying = dai;
        address toCurvePool = three_pool;
        address toCurveLP = three_crv;
        bytes4 toCurveFunctionSig = bytes4(
            keccak256(bytes("add_liquidity(uint256[3],uint256)"))
        );
        uint256 toCurvePoolSize = uint256(3);
        uint256 toCurveUnderlyingIndex = uint256(0);

        _test_curve_curve_swap(
            fromIndex,
            toIndex,
            fromUnderlyingAmount,
            abi.encode(
                fromUnderlying,
                fromCurvePool,
                fromCurveLP,
                fromCurveFunctionSig,
                fromCurvePoolSize,
                fromCurveUnderlyingIndex,
                toUnderlying,
                toCurvePool,
                toCurveLP,
                toCurveFunctionSig,
                toCurvePoolSize,
                toCurveUnderlyingIndex
            )
        );
        _post_swap_check(fromIndex, toIndex);
    }

    function test_jar_converter_curve_curve_2_1() public {
        uint256 fromIndex = 2;
        uint256 toIndex = 1;
        uint256 fromUnderlyingAmount = 4e6;

        address fromUnderlying = wbtc;
        address fromCurvePool = ren_pool;
        address fromCurveLP = ren_crv;
        bytes4 fromCurveFunctionSig = bytes4(
            keccak256(bytes("remove_liquidity(uint256,uint256[2])"))
        );
        uint256 fromCurvePoolSize = uint256(2);
        uint256 fromCurveUnderlyingIndex = uint256(1);

        address toUnderlying = dai;
        address toCurvePool = susdv2_pool;
        address toCurveLP = scrv;
        bytes4 toCurveFunctionSig = bytes4(
            keccak256(bytes("add_liquidity(uint256[4],uint256)"))
        );
        uint256 toCurvePoolSize = uint256(4);
        uint256 toCurveUnderlyingIndex = uint256(0);

        _test_curve_curve_swap(
            fromIndex,
            toIndex,
            fromUnderlyingAmount,
            abi.encode(
                fromUnderlying,
                fromCurvePool,
                fromCurveLP,
                fromCurveFunctionSig,
                fromCurvePoolSize,
                fromCurveUnderlyingIndex,
                toUnderlying,
                toCurvePool,
                toCurveLP,
                toCurveFunctionSig,
                toCurvePoolSize,
                toCurveUnderlyingIndex
            )
        );
        _post_swap_check(fromIndex, toIndex);
    }
}
