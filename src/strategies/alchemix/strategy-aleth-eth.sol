// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-base-symbiotic.sol";
import "../../interfaces/alcx-farm.sol";

contract StrategySaddleAlethEth is StrategyBaseSymbiotic {
    address public alethEthlp = 0xc9da65931ABf0Ed1b74Ce5ad8c041C4220940368;

    uint256 public alcxPoolId = 1;

    uint256 public alEthPoolId = 6;

    address public constant alcx = 0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBaseSymbiotic(
            alethEthlp,
            alcx,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategySaddleAlethEth";
    }

    function getHarvestable() public view returns (uint256) {
        return
            IStakingPools(stakingPool).getStakeTotalUnclaimed(
                address(this),
                alEthPoolId
            );
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

        if (getHarvestable() > 0) IStakingPools(stakingPool).claim(alEthPoolId);

        _distributePerformanceFeesAndRewardDeposit();
    }

    function withdrawReward(uint256 _amount) external {
        require(msg.sender == controller, "!controller");
        address _jar = IController(controller).jars(address(want));
        address reward_token = IJar(_jar).reward();
        uint256 _balance = IERC20(reward).balanceOf(address(this));
        uint256 _pendingReward = pendingReward();
        require(
            reward_token != address(0),
            "Reward token is not set in the pickle jar"
        );
        require(reward_token == reward, "Reward token is invalid");
        require(
            _pendingReward >= _amount,
            "[withdrawReward] Withdraw amount exceed redeemable amount"
        );

        _balance = IERC20(reward).balanceOf(address(this));
        if (_balance < _amount && getRewardHarvestable() > 0)
            IStakingPools(stakingPool).claim(alcxPoolId);

        _balance = IERC20(reward).balanceOf(address(this));
        if (_balance < _amount && getHarvestable() > 0)
            IStakingPools(stakingPool).claim(alEthPoolId);

        _balance = IERC20(reward).balanceOf(address(this));
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
            IERC20(reward).balanceOf(address(this)).add(
                IStakingPools(stakingPool)
                    .getStakeTotalDeposited(address(this), alcxPoolId)
                    .add(getHarvestable().add(getRewardHarvestable()))
            );
    }

    function balanceOfPool() public view override returns (uint256) {
        uint256 amount = IStakingPools(stakingPool).getStakeTotalDeposited(
            address(this),
            alEthPoolId
        );
        return amount;
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(stakingPool, 0);
            IERC20(want).safeApprove(stakingPool, _want);

            IStakingPools(stakingPool).deposit(alEthPoolId, _want);
        }
    }

    function rewardDeposit() public override {
        uint256 _reward = IERC20(reward).balanceOf(address(this));
        if (_reward > 0) {
            IERC20(reward).safeApprove(stakingPool, 0);
            IERC20(reward).safeApprove(stakingPool, _reward);

            IStakingPools(stakingPool).deposit(alcxPoolId, _reward); //stake to alcx farm
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IStakingPools(stakingPool).withdraw(alEthPoolId, _amount);
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
