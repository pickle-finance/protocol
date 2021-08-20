// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base-convex-flywheel.sol";

contract StrategyCvxCRVFlywheel is StrategyBaseConvexFlywheel {

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBaseConvexFlywheel(
            cvxCRV, // want
            cvx, // reward
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    function getName() external pure override returns (string memory) {
        return "StrategyCvxCRVFlywheel";
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
        if (_balance < _amount && get_cvx_earned() > 0)
            claim_cvxcrv_staking();

        _balance = IERC20(reward).balanceOf(address(this));
        if (_balance < _amount) {
            uint256 _r = _amount.sub(_balance);
            _withdraw_some_cvx(_r);
        }
        _balance = IERC20(reward).balanceOf(address(this));
        require(
            _balance >= _amount,
            "[WithdrawReward] Withdraw amount exceed balance"
        ); //double check
        IERC20(reward_token).safeTransfer(_jar, _amount);

        rewardDeposit();
    }

    function deposit() public override {
        _deposit_cvxcrv();
    }

    function rewardDeposit() public override {
        _deposit_cvx();
    }

    function getRewardDeposited() public view override returns (uint256) {
        return _balance_cvx_stake();
    }

    function pendingReward() public view returns (uint256) {
        return _pending_cvx();
    }

    function balanceOfPool() public view override returns (uint256) {
        return _balance_cvxcrv_stake();
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        return _withdraw_some_cvxcrv();
    }

    function _withdrawSomeReward(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        return _withdraw_some_cvx();
    }
}
