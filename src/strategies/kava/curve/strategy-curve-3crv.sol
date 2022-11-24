// SPDX-License-Identifier: MIT
pragma solidity >=0.8.6;

import "../../../lib/erc20.sol";
import "../../../lib/safe-math.sol";

import "../../../interfaces/jar.sol";
import "../../../interfaces/curve.sol";
import "../../../interfaces/uniswapv2.sol";
import "../../../interfaces/controller.sol";

import "../strategy-curve-base.sol";

contract StrategyKavaCurve3Crv is StrategyCurveBase {
    using SafeERC20 for IERC20;
    using Address for address;
    using SafeMath for uint256;

    // Curve stuff
    address public tri_pool = 0x7A0e3b70b1dB0D6CA63Cac240895b2D21444A7b9;
    address public tri_token = tri_pool;
    address public tri_gauge = 0x8004216BED6B6A8E6653ACD0d45c570ed712A632;
    address public usdc_kava_slp = 0x88395b86cF9787E131D2fB5462a22b44056BF574;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    ) StrategyCurveBase(tri_pool, tri_gauge, tri_token, _governance, _strategist, _controller, _timelock) {
        IERC20(kava).approve(address(bento), type(uint256).max);
        IERC20(usdc).approve(address(curve), type(uint256).max);
    }

    function getName() external pure override returns (string memory) {
        return "StrategyKavaCurve3Crv";
    }

    // **** State Mutations ****

    function harvest() public override {
        ICurveGauge(gauge).claim_rewards(address(this));

        uint256 _kava = IERC20(kava).balanceOf(address(this));
        // Adds liquidity to curve.fi's pool
        if (_kava > 0) {
            IERC20(kava).safeTransfer(
                IController(controller).treasury(),
                _kava.mul(performanceTreasuryFee).div(performanceTreasuryMax)
            );

            _kava = IERC20(kava).balanceOf(address(this));
            // Swap for USDC on Trident
            ITridentRouter.Path[] memory _path = new ITridentRouter.Path[](1);

            _path[0] = ITridentRouter.Path({pool: usdc_kava_slp, data: abi.encode(kava, address(this), true)});
            _swapTridentWithPath(_path, _kava);

            uint256 _usdc = IERC20(usdc).balanceOf(address(this));

            if (_usdc > 0) {
                ICurveFi_3(curve).add_liquidity([0, _usdc, 0], 0);
                deposit();
            }
        }
    }
}
