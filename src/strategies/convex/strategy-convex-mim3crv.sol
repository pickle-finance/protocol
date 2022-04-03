pragma solidity ^0.6.7;

import "../strategy-convex-farm-base.sol";

interface ICurveZapper {
    function add_liquidity(
        address,
        uint256[4] calldata,
        uint256
    ) external returns (uint256);
}

contract StrategyConvexMim3Crv is StrategyConvexFarmBase {
    address public lpToken = 0x5a6A4D54456819380173272A5E8E9B9904BdF41B;
    uint256 public mim3crvPoolId = 40;
    address public dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public spell = 0x090185f2135308BaD17527004364eBcC2D37e5F6;
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
            mim3crvPoolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    function getName() external pure override returns (string memory) {
        return "StrategyConvexMim3Crv";
    }

    function get_spell_earned() public view returns (uint256) {
        return
            IVirtualBalanceRewardPool(
                IBaseRewardPool(getCrvRewardContract()).extraRewards(0)
            ).earned(address(this));
    }

    function getHarvestable()
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (get_crv_earned(), get_cvx_earned(), get_spell_earned());
    }

    function harvest() public override onlyBenevolent {
        (
            uint256 _crvHarvestable,
            uint256 _cvxHarvestable,
            uint256 _spellHarvestable
        ) = getHarvestable();

        if (_crvHarvestable > 0 || _cvxHarvestable > 0 || _spellHarvestable > 0)
            IBaseRewardPool(getCrvRewardContract()).getReward(
                address(this),
                true
            );

        address[] memory path = new address[](3);
        path[1] = weth;
        path[2] = dai;

        uint256 _cvx = IERC20(cvx).balanceOf(address(this));
        if (_cvx > 0) {
            IERC20(cvx).safeApprove(sushiRouter, 0);
            IERC20(cvx).safeApprove(sushiRouter, _cvx);
            path[0] = cvx;
            _swapSushiswapWithPath(path, _cvx);
        }

        uint256 _crv = IERC20(crv).balanceOf(address(this));

        if (_crv > 0) {
            IERC20(crv).safeApprove(sushiRouter, 0);
            IERC20(crv).safeApprove(sushiRouter, _crv);
            path[0] = crv;
            _swapSushiswapWithPath(path, _crv);
        }

        uint256 _spell = IERC20(spell).balanceOf(address(this));

        if (_spell > 0) {
            IERC20(spell).safeApprove(sushiRouter, 0);
            IERC20(spell).safeApprove(sushiRouter, _spell);
            path[0] = spell;
            _swapSushiswapWithPath(path, _spell);
        }

        uint256 _dai = IERC20(dai).balanceOf(address(this));
        if (_dai > 0) {
            IERC20(dai).safeApprove(zapper, 0);
            IERC20(dai).safeApprove(zapper, _dai);

            uint256[4] memory amounts = [0, _dai, 0, 0];
            ICurveZapper(zapper).add_liquidity(lpToken, amounts, 0);
        }

        _distributePerformanceFeesAndDeposit();
    }
}
