// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-convex-farm-base.sol";
import "../../interfaces/steth.sol";
import "../../interfaces/weth.sol";

contract StrategyConvexSteCRV is StrategyConvexFarmBase {
    address public stEth = 0xae7ab96520DE3A18E5e111B5EaAb095312D7fE84;
    address public lpToken = 0x06325440D014e39736583c165C2963BA99fAf14E; // steCRV

    address public pool = 0xDC24316b9AE028F1497c275EB9192a3Ea0f67022; // Curve ETH-stETH

    // extra reward
    address public constant ldo = 0x5A98FcBEA516Cf06857215779Fd812CA3beF1B32;

    uint256 public constant cvxPoolId = 25;

    // How much CVX tokens to keep
    uint256 public keepCVX = 500;
    uint256 public keepCVXMax = 10000;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyConvexFarmBase(
            lpToken,
            cvxPoolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // swap for eth
    receive() external payable {}

    // **** Getters ****

    function getName() external pure override returns (string memory) {
        return "StrategyConvexSteCRV";
    }

    function getHarvestable()
        public
        view
        returns (
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            get_crv_earned(),
            get_cvx_earned(),
            get_ldo_earned(),
            get_eth_earned()
        );
    }

    function get_ldo_earned() public view returns (uint256) {
        return
            IVirtualBalanceRewardPool(
                IBaseRewardPool(getCrvRewardContract()).extraRewards(0)
            ).earned(address(this));
    }

    function get_eth_earned() public view returns (uint256) {
        uint256 claimableCrv = get_crv_earned();
        uint256 claimableLdo = get_ldo_earned();
        uint256 claimableCvx = get_cvx_earned();

        uint256 crvEth = _estimateSell(crv, claimableCrv);
        uint256 ldoEth = _estimateSell(ldo, claimableLdo);
        uint256 cvxEth = _estimateSell(cvx, claimableCvx);

        return crvEth.add(ldoEth).add(cvxEth);
    }

    function _estimateSell(address currency, uint256 amount)
        internal
        view
        returns (uint256 outAmount)
    {
        address[] memory path = new address[](2);
        path[0] = currency;
        path[1] = weth;
        uint256[] memory amounts = UniswapRouterV2(sushiRouter).getAmountsOut(
            amount,
            path
        );
        outAmount = amounts[amounts.length - 1];

        return outAmount;
    }

    // **** Setters ****

    function setKeepCVX(uint256 _keepCVX) external {
        require(msg.sender == governance, "!governance");
        keepCVX = _keepCVX;
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        IBaseRewardPool(getCrvRewardContract()).getReward(address(this), true);

        uint256 _cvx = IERC20(cvx).balanceOf(address(this));
        if (_cvx > 0) {
            // How much CVX to keep to restake?
            uint256 _keepCVX = _cvx.mul(keepCVX).div(keepCVXMax);
            if (_keepCVX > 0) {
                IERC20(cvx).safeTransfer(
                    IController(controller).treasury(),
                    _keepCVX
                );
            }

            // How much CVX to swap?
            _cvx = _cvx.sub(_keepCVX);
            IERC20(cvx).safeApprove(sushiRouter, 0);
            IERC20(cvx).safeApprove(sushiRouter, _cvx);
            _swapSushiswap(cvx, weth, _cvx);
        }

        uint256 _ldo = IERC20(ldo).balanceOf(address(this));
        if (_ldo > 0) {
            IERC20(ldo).safeApprove(sushiRouter, 0);
            IERC20(ldo).safeApprove(sushiRouter, _ldo);
            _swapSushiswap(ldo, weth, _ldo);
        }

        uint256 _crv = IERC20(crv).balanceOf(address(this));
        if (_crv > 0) {
            IERC20(crv).safeApprove(sushiRouter, 0);
            IERC20(crv).safeApprove(sushiRouter, _crv);
            _swapSushiswap(crv, weth, _crv);
        }
        WETH(weth).withdraw(WETH(weth).balanceOf(address(this)));

        uint256 _eth = address(this).balance;
        IStEth(stEth).submit{value: _eth / 2}(strategist);
        _eth = address(this).balance;

        uint256 _stEth = IStEth(stEth).balanceOf(address(this));
        if (_stEth > 0) {
            uint256[2] memory liquidity = [_eth, _stEth];
            IERC20(stEth).safeApprove(pool, 0);
            IERC20(stEth).safeApprove(pool, _stEth);
            // ICurveFi_4(pool).add_liquidity{value: _eth}(liquidity, 0);
        }

        _distributePerformanceFeesAndDeposit();
    }
}
