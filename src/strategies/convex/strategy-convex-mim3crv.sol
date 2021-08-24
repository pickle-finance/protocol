pragma solidity ^0.6.7;

import "../strategy-convex-farm-base.sol";

interface ICurveZapper {
    function add_liquidity(
        address,
        uint256[4] memory,
        uint256
    ) external returns (uint256);
}

contract StrategyConvexMim3Crv is StrategyConvexFarmBase {
    address public lpToken = 0x5a6A4D54456819380173272A5E8E9B9904BdF41B;
    uint256 public crvTricryptoPoolId = 40;
    address public mim = 0x99D8a9C45b2ecA8864373A26D1459e3Dff1e17F3;
    address public zapper = 0xA79828DF1850E8a3A3064576f380D90aECDD3359;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyConvexFarmBase(
            lpToken,
            crvTricryptoPoolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    function getName() external pure override returns (string memory) {
        return "StrategyConvexMim3Crv";
    }

    function getHarvestable() public view returns (uint256, uint256) {
        return (get_crv_earned(), get_cvx_earned());
    }

    function harvest() public override onlyBenevolent {
        (uint256 _crvHarvestable, uint256 _cvxHarvestable) = getHarvestable();

        if (_crvHarvestable > 0 || _cvxHarvestable > 0)
            IBaseRewardPool(getCrvRewardContract()).getReward(
                address(this),
                true
            );

        uint256 _cvx = IERC20(cvx).balanceOf(address(this));
        if (_cvx > 0) {
            IERC20(cvx).safeApprove(sushiRouter, 0);
            IERC20(cvx).safeApprove(sushiRouter, _cvx);
            _swapSushiswap(cvx, weth, _cvx);
        }
        uint256 _crv = IERC20(crv).balanceOf(address(this));

        if (_crv > 0) {
            IERC20(crv).safeApprove(sushiRouter, 0);
            IERC20(crv).safeApprove(sushiRouter, _crv);
            _swapSushiswap(crv, weth, _crv);
        }

        uint256 _weth = IERC20(weth).balanceOf(address(this));
        if (_weth > 0) {
            IERC20(weth).safeApprove(sushiRouter, 0);
            IERC20(weth).safeApprove(sushiRouter, _weth);
            _swapSushiswap(weth, mim, _weth);
        }

        uint256 _mim = IERC20(mim).balanceOf(address(this));
        if (_mim > 0) {
            IERC20(mim).safeApprove(zapper, 0);
            IERC20(mim).safeApprove(zapper, _mim);

            uint256[4] memory amounts = [_mim, 0, 0, 0];
            ICurveZapper(zapper).add_liquidity(lpToken, amounts, 0);
        }

        _distributePerformanceFeesAndDeposit();
    }
}
