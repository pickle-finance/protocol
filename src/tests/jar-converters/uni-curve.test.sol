// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

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

import "../../strategies/uniswapv2/strategy-uni-eth-dai-lp-v3_1.sol";
import "../../strategies/uniswapv2/strategy-uni-eth-usdt-lp-v3_1.sol";
import "../../strategies/uniswapv2/strategy-uni-eth-usdc-lp-v3_1.sol";
import "../../strategies/uniswapv2/strategy-uni-eth-wbtc-lp-v1.sol";

import "../../strategies/curve/strategy-curve-scrv-v3_1.sol";
import "../../strategies/curve/strategy-curve-rencrv-v1.sol";
import "../../strategies/curve/strategy-curve-3crv-v1.sol";

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
                curveStrategies[0].want(),
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
                uniStrategies[0].want(),
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

        uint256 _token1 = IERC20(other).balanceOf(address(this));

        IERC20(other).safeApprove(address(univ2), 0);
        IERC20(other).safeApprove(address(univ2), _token1);

        univ2.addLiquidityETH{value: ethAmount}(
            other,
            _token1,
            0,
            0,
            address(this),
            now + 60
        );
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

    // Tests
    function test_jar_converter_uni_curve_0() public {
        // Deposit into PickleJars
        address from = address(uniPickleJars[0].token());
        _getUniLP(from, 1e18, 400e18);

        uint256 _from = IERC20(from).balanceOf(address(this));
        IERC20(from).approve(address(uniPickleJars[0]), _from);
        uniPickleJars[0].deposit(_from);

        // Swap!
        uint256 _fromPickleJar = IERC20(address(uniPickleJars[0])).balanceOf(
            address(this)
        );
        IERC20(address(uniPickleJars[0])).approve(
            address(controller),
            _fromPickleJar
        );

        uint256 _before = IERC20(address(curvePickleJars[0])).balanceOf(
            address(this)
        );

        bytes memory data = abi.encode(
            three_pool,
            bytes4(keccak256(bytes("add_liquidity(uint256[3],uint256)"))),
            uint256(3), // 3 pool size
            uint256(0), // Dai index 0
            from,
            dai,
            three_crv,
            dai
        );

        controller.swapExactJarForJar(
            address(uniPickleJars[0]),
            address(curvePickleJars[0]),
            _fromPickleJar,
            address(uniCurveJarConverter),
            data
        );

        uint256 _after = IERC20(address(curvePickleJars[0])).balanceOf(
            address(this)
        );

        assertTrue(_after > _before);
    }
}
