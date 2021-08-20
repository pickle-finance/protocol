// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-base-symbiotic.sol";
import "../interfaces/curve.sol";
import "../interfaces/convex-farm.sol";

abstract contract StrategyBaseConvexFlywheel is StrategyBaseSymbiotic {
    address public constant cvx = 0x4e3FBD56CD56c3e72c1403e103b45Db9da5B9D2B;
    address public constant cvxCRV = 0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7;

    address public crvDepositor = 0x8014595F2AB54cD7c604B00E9fb932176fDc86Ae; // crv to cvxCRV
    address public cvxSingleStake = 0xCF50b810E57Ac33B91dCF525C6ddd9881B139332; // rewards cvxCRV
    address public cvxCRVSingleStake = 0x3Fe65692bfCD0e6CF84cB1E7d24108E434A7587e; // rewards (CRV, 3crv, CVX)

    address public constant threeCrv = 0x6c3F90f043a72FA612cbac8115EE7e52BDe6E490;
    address public constant threePool = 0xbEbc44782C7dB0a1A60Cb6fe97d0b483032FF1C7;

    // **** Views ****

    function getLeastPremium()
        public
        override
        view
        returns (address, uint256)
    {
        uint256[] memory balances = new uint256[](3);
        balances[0] = ICurveFi_3(curve).balances(0); // DAI
        balances[1] = ICurveFi_3(curve).balances(1).mul(10**12); // USDC
        balances[2] = ICurveFi_3(curve).balances(2).mul(10**12); // USDT

        // DAI
        if (
            balances[0] > balances[1] &&
            balances[0] > balances[2]
        ) {
            return (dai, 0);
        }

        // USDC
        if (
            balances[1] > balances[0] &&
            balances[1] > balances[2]
        ) {
            return (usdc, 1);
        }

        // USDT
        if (
            balances[2] > balances[0] &&
            balances[2] > balances[1]
        ) {
            return (usdt, 2);
        }

        // If they're somehow equal, we just want DAI
        return (dai, 0);
    }

    function get_cvxcrv_earned() public view returns (uint256) {
        return ICvxRewardPool(cvxSingleStake).earned(address(this));
    }

    function get_crv_earned() public view returns (uint256) {
        return IBaseRewardPool(cvxCRVSingleStake).earned(address(this));
    }

    function get_3crv_earned() public view returns (uint256) {
        return
            IVirtualBalanceRewardPool(
                IBaseRewardPool(cvxCRVSingleStake).extraRewards(0)
            ).earned(address(this));
    }

    function get_cvx_earned() public view returns (uint256) {
        uint256 crv_earned = get_crv_earned();

        uint256 supply = IConvexToken(cvx).totalSupply();
        if (supply == 0) {
            return crv_earned;
        }
        uint256 reductionPerCliff = IConvexToken(cvx).reductionPerCliff();
        uint256 totalCliffs = IConvexToken(cvx).totalCliffs();
        uint256 cliff = supply.div(reductionPerCliff);

        uint256 maxSupply = IConvexToken(cvx).maxSupply();

        if (cliff < totalCliffs) {
            uint256 reduction = totalCliffs.sub(cliff);
            uint256 _amount = crv_earned;

            _amount = _amount.mul(reduction).div(totalCliffs);
            //supply cap check
            uint256 amtTillMax = maxSupply.sub(supply);
            if (_amount > amtTillMax) {
                _amount = amtTillMax;
            }
            return _amount;
        }
        return 0;
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        if (get_cvxcrv_earned() > 0)
            _claim_cvx_staking();

        if (get_crv_earned() > 0 || get_3crv_earned() > 0)
            _claim_cvxcrv_staking();
            
        // swap 3crv for cvx
        uint256 _balance = IERC20(threeCrv).balanceOf(address(this));
        if (_balance > 0) {
            (address stable, uint256 idx) = getLeastPremium();
            
            IERC20(threeCrv).safeApprove(threePool, 0);
            IERC20(threeCrv).safeApprove(threePool, _balance);
            ICurveZap(threePool).remove_liquidity_one_coin(
                _balance,
                idx,
                0
            );
            
            uint256 _balance = IERC20(stable).balanceOf(address(this));
            if (_balance > 0) {
                IERC20(stable).safeApprove(sushiRouter, 0);
                IERC20(stable).safeApprove(sushiRouter, _balance);
                _swapSushiswap(stable, cvx, _balance);
            }
        }
        
        // lock crv
        // CVX ClaimZap has ability to swap through Sushi's CRV/cvxCRV pair
        // but the decision is made off chain
        _balance = IERC20(crv).balanceOf(address(this));
        if (_balance > 0) {
            IERC20(crv).safeApprove(crvDepositor, 0);
            IERC20(crv).safeApprove(crvDepositor, _balance);
            ICvxCrvDeposit(crvDepositor).deposit(_balance, false);
        }

        _distributePerformanceFeesAndRewardDeposit();
    }

    function _claim_cvx_staking() internal {
        IBaseRewardPool(cvxSingleStake).getReward(false);
    }

    function _claim_cvxcrv_staking() internal {
        IBaseRewardPool(cvxCRVSingleStake).getReward();
    }

    function pending_cvx() public view returns (uint256) {
        return
            IERC20(cvx).balanceOf(address(this)).add(
                get_cvx_earned()
                .add(balance_cvx_stake())
            );
    }

    function pending_cvxcrv() public view returns (uint256) {
        return
            IERC20(cvxCRV).balanceOf(address(this)).add(
                get_cvxcrv_earned()
                .add(balance_cvxcrv_stake())
            );
    }

    function balance_cvx_stake() public view returns (uint256) {
        return ICvxRewardPool(cvxSingleStake).balanceOf(address(this));
    }

    function balance_cvxcrv_stake() public view returns (uint256) {
        return IBaseRewards(cvxCRVSingleStake).balanceOf(address(this));
    }

    // **** Setters ****

    function _deposit_cvx() internal {
        uint256 _cvx = IERC20(cvx).balanceOf(address(this));
        if (_cvx > 0) {
            IERC20(cvx).safeApprove(cvxSingleStake, 0);
            IERC20(cvx).safeApprove(cvxSingleStake, _cvx);
            ICvxRewardPool(cvxSingleStake).stake(_cvx);
        }
    }

    function _deposit_cvxcrv() internal {
        uint256 _cvxcrv = IERC20(cvxCRV).balanceOf(address(this));
        if (_cvxcrv > 0) {
            IERC20(cvxCRV).safeApprove(cvxCRVSingleStake, 0);
            IERC20(cvxCRV).safeApprove(cvxCRVSingleStake, _cvxcrv);
            IBasicRewards(cvxCRVSingleStake).stake(_cvxcrv);
        }
    }

    function _withdraw_some_cvx(uint256 _amount) internal returns (uint256)
    {
        ICvxRewardPool(cvxSingleStake).withdraw(_amount, false);
        return _amount;
    }

    function _withdraw_some_cvxcrv(uint256 _amount) internal returns (uint256)
    {
        IBasicRewards(cvxCRVSingleStake).withdraw(_amount, false);
        return _amount;
    }
}
