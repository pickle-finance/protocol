pragma solidity ^0.6.7;

import "./strategy-base.sol";

// Base contract for SNX Staking rewards contract interfaces

abstract contract StrategyStakingRewardsBase is StrategyBase {
    address public rewards;

    // **** Getters ****
    constructor(
        address _rewards,
        address _want,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(_want, _governance, _strategist, _controller, _timelock)
    {
        rewards = _rewards;
    }

    function balanceOfPool() public override view returns (uint256) {
        return IStakingRewards(rewards).balanceOf(address(this));
    }

    function getHarvestable() external override view returns (uint256) {
        return IStakingRewards(rewards).earned(address(this));
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(rewards, 0);
            IERC20(want).safeApprove(rewards, _want);
            IStakingRewards(rewards).stake(_want);
        }
    }

    // Withdraw partial funds, normally used with a jar withdrawal
    function withdraw(uint256 _amount) external override {
        require(msg.sender == controller, "!controller");
        uint256 _balance = IERC20(want).balanceOf(address(this));
        if (_balance < _amount) {
            _amount = _withdrawSome(_amount.sub(_balance));
            _amount = _amount.add(_balance);
        }

        uint256 _feeDev = _amount.mul(devFundFee).div(devFundMax);
        IERC20(want).safeTransfer(IController(controller).devfund(), _feeDev);

        uint256 _feeTreasury = _amount.mul(treasuryFee).div(treasuryMax);
        IERC20(want).safeTransfer(
            IController(controller).treasury(),
            _feeTreasury
        );

        address _jar = IController(controller).jars(address(want));
        require(_jar != address(0), "!jar"); // additional protection so we don't burn the funds

        IERC20(want).safeTransfer(_jar, _amount.sub(_feeDev).sub(_feeTreasury));
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IStakingRewards(rewards).withdraw(_amount);
        return _amount;
    }
}
