pragma solidity ^0.6.7;
pragma experimental ABIEncoderV2;

import "../strategy-convex-farm-base.sol";

contract StrategyConvexCvxfxsLp is StrategyConvexFarmBase {
    address public constant lpToken =
        0xF3A43307DcAFa93275993862Aae628fCB50dC768;
    uint256 public constant cvxfxsPoolId = 72;
    address public constant pool = 0xd658A338613198204DCa1143Ac3F01A722b5d94A;
    address public constant fxs = 0x3432B6A60D23Ca0dFCa7761B7ab56459D9C964D0;

    uint24 public constant poolFee = 10000;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyConvexFarmBase(
            lpToken,
            cvxfxsPoolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        IERC20(cvx).safeApprove(univ3Router, uint256(-1));
        IERC20(crv).safeApprove(univ3Router, uint256(-1));
        IERC20(fxs).safeApprove(pool, uint256(-1));
    }

    function getName() external pure override returns (string memory) {
        return "StrategyConvexCvxfxsLp";
    }

    function get_cvx_earned()
        public
        view
        override
        returns (uint256 cvxRewards)
    {
        address cvxRewardsContract = IBaseRewardPool(getCrvRewardContract())
            .extraRewards(0);
        cvxRewards = IBaseRewardPool(cvxRewardsContract).earned(address(this));
    }

    function get_fxs_earned()
        public
        view
        returns (uint256 fxsRewards)
    {
        address fxsRewardsContract = IBaseRewardPool(getCrvRewardContract())
            .extraRewards(1);
        fxsRewards = IBaseRewardPool(fxsRewardsContract).earned(address(this));
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
        return (get_crv_earned(), get_cvx_earned(), get_fxs_earned());
    }

    function harvest() public override onlyBenevolent {
        IBaseRewardPool(getCrvRewardContract()).getReward(address(this), true);

        uint256 _cvx = IERC20(cvx).balanceOf(address(this));

        if (_cvx > 0) {
            ISwapRouter(univ3Router).exactInput(
                ISwapRouter.ExactInputParams({
                    path: abi.encodePacked(cvx, poolFee, weth, poolFee, fxs),
                    recipient: address(this),
                    deadline: block.timestamp + 300,
                    amountIn: _cvx,
                    amountOutMinimum: 0
                })
            );
        }
        uint256 _crv = IERC20(crv).balanceOf(address(this));

        if (_crv > 0) {
            ISwapRouter(univ3Router).exactInput(
                ISwapRouter.ExactInputParams({
                    path: abi.encodePacked(crv, poolFee, weth, poolFee, fxs),
                    recipient: address(this),
                    deadline: block.timestamp + 300,
                    amountIn: _crv,
                    amountOutMinimum: 0
                })
            );
        }
        uint256 _fxs = IERC20(fxs).balanceOf(address(this));
        if (_fxs > 0) {
            uint256[2] memory amounts = [_fxs, 0];
            ICurveFi_4(pool).add_liquidity(amounts, 0);
        }

        _distributePerformanceFeesAndDeposit();
    }
}
