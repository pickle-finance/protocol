// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-base-symbiotic.sol";
import "../../interfaces/alcx-farm.sol";
import "../../interfaces/convex-farm.sol";

contract StrategyAlusd3Crv is StrategyBaseSymbiotic {
    address public alusd_3crv = 0x43b4FdFD4Ff969587185cDB6f0BD875c5Fc83f8c;

    uint256 public alcxPoolId = 1;

    uint256 public alusdPoolId = 36;

    address public constant alcx = 0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF;

    address public constant convexBooster =
        0xF403C135812408BFbE8713b5A23a04b3D48AAE31;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBaseSymbiotic(
            alusd_3crv,
            alcx,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyAlusd3Crv";
    }

    function get_crv_earned() public view returns (uint256) {
        return IBaseRewardPool(getCrvRewardContract()).earned(address(this));
    }

    function get_alcx_earned() public view returns (uint256) {
        return
            IVirtualBalanceRewardPool(getAlcxRewardContract()).earned(
                address(this)
            );
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

    function getHarvestable()
        public
        view
        returns (
            uint256,
            uint256,
            uint256
        )
    {
        return (get_crv_earned(), get_cvx_earned(), get_alcx_earned());
    }

    function getRewardHarvestable() public view returns (uint256) {
        return
            IStakingPools(stakingPool).getStakeTotalUnclaimed(
                address(this),
                alcxPoolId
            );
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Collects Alcx tokens

        if (getRewardHarvestable() > 0)
            IStakingPools(stakingPool).claim(alcxPoolId); //claim from alcx staking pool

        (
            uint256 _crvHarvestable,
            uint256 _cvxHarvestable,
            uint256 _alcxHarvestable
        ) = getHarvestable();

        if (_crvHarvestable > 0 || _cvxHarvestable > 0 || _alcxHarvestable > 0)
            IBaseRewardPool(getCrvRewardContract()).getReward(
                address(this),
                true
            ); //claim from alusd_3crv staking pool

        uint256 _cvx = IERC20(cvx).balanceOf(address(this));
        if (_cvx > 0) {
            IERC20(cvx).safeApprove(sushiRouter, 0);
            IERC20(cvx).safeApprove(sushiRouter, _cvx);
            _swapSushiswap(cvx, alcx, _cvx);
        }
        uint256 _crv = IERC20(crv).balanceOf(address(this));

        if (_crv > 0) {
            IERC20(crv).safeApprove(sushiRouter, 0);
            IERC20(crv).safeApprove(sushiRouter, _crv);
            _swapSushiswap(crv, alcx, _crv);
        }

        _distributePerformanceFeesAndRewardDeposit();
    }

    function withdrawReward(uint256 _amount) external {
        require(msg.sender == controller, "!controller");
        address _jar = IController(controller).jars(address(want));
        address reward_token = IJar(_jar).reward();
        uint256 _balance = IERC20(alcx).balanceOf(address(this));
        uint256 _pendingReward = pendingReward();
        require(
            reward_token != address(0),
            "Reward token is not set in the pickle jar"
        );
        require(reward_token == alcx, "Reward token is invalid");
        require(
            _pendingReward >= _amount,
            "[withdrawReward] Withdraw amount exceed redeemable amount"
        );

        uint256 _alcxHarvestable = getRewardHarvestable();
        uint256 _alcx_earned = get_alcx_earned();

        _balance = IERC20(alcx).balanceOf(address(this));
        if (_balance < _amount && _alcxHarvestable > 0)
            IStakingPools(stakingPool).claim(alcxPoolId);

        _balance = IERC20(alcx).balanceOf(address(this));
        if (_balance < _amount && _alcx_earned > 0)
            IVirtualBalanceRewardPool(getAlcxRewardContract()).getReward(
                address(this)
            );

        _balance = IERC20(alcx).balanceOf(address(this));
        if (_balance < _amount) {
            uint256 _r = _amount.sub(_balance);
            uint256 _alcxDeposited = getRewardDeposited();
            IStakingPools(stakingPool).withdraw(
                alcxPoolId,
                _alcxDeposited >= _r ? _r : _alcxDeposited
            );
        }
        _balance = IERC20(alcx).balanceOf(address(this));
        require(
            _balance >= _amount,
            "[WithdrawReward] Withdraw amount exceed balance"
        ); //double check
        IERC20(reward_token).safeTransfer(_jar, _amount);
        rewardDeposit();
    }

    function getRewardDeposited() public view override returns (uint256) {
        return
            IStakingPools(stakingPool).getStakeTotalDeposited(
                address(this),
                alcxPoolId
            );
    }

    function pendingReward() public view returns (uint256) {
        return
            IERC20(alcx).balanceOf(address(this)).add(
                IStakingPools(stakingPool)
                    .getStakeTotalDeposited(address(this), alcxPoolId)
                    .add(get_alcx_earned().add(getRewardHarvestable()))
            );
    }

    function getCrvRewardContract() public view returns (address) {
        (, , , address crvRewards, , ) = IConvexBooster(
            0xF403C135812408BFbE8713b5A23a04b3D48AAE31
        ).poolInfo(alusdPoolId);
        return crvRewards;
    }

    function getAlcxRewardContract() public view returns (address) {
        return IBaseRewardPool(getCrvRewardContract()).extraRewards(0);
    }

    function balanceOfPool() public view override returns (uint256) {
        uint256 amount = IBaseRewardPool(getCrvRewardContract()).balanceOf(
            address(this)
        );
        return amount;
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(convexBooster, 0);
            IERC20(want).safeApprove(convexBooster, _want);

            IConvexBooster(convexBooster).deposit(alusdPoolId, _want, true);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IBaseRewardPool(getCrvRewardContract()).withdrawAndUnwrap(
            _amount,
            false
        );
        return _amount;
    }

    function _withdrawSomeReward(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IStakingPools(stakingPool).withdraw(alcxPoolId, _amount);
        return _amount;
    }
}
