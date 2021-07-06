// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../interfaces/ISorbettoFragola.sol";

abstract contract StrategySorbettoBase is StrategyBase {
    address public token0;
    address public token1;

    // How much SUSHI tokens to keep?
    uint256 public keepReward = 0;
    uint256 public constant keepRewardMax = 10000;

    constructor(
        address _token0,
        address _token1,
        address _lp,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(
            _lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        token1 = _token1;
        token0 = _token0;
        IERC20(token0).safeApprove(_lp, uint(-1));
        IERC20(token1).safeApprove(_lp, uint(-1));
    }
    
    function balanceOfPool() public override view returns (uint256) {
        return 0;
    }

    function getHarvestable() external view returns (uint256, uint256) {
        (uint256 token0Rewards, uint256 token1Rewards,,) = ISorbettoFragola(want).userInfo(address(this));
        return (token0Rewards, token1Rewards);
    }

    // **** Setters ****

    function deposit() public override {}

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        return _amount;
    }

    // **** Setters ****

    function setKeepReward(uint256 _keepReward) external {
        require(msg.sender == timelock, "!timelock");
        keepReward = _keepReward;
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects SUSHI tokens
        ISorbettoFragola(want).deposit(0, 0);
        (uint256 amount0, uint256 amount1,,) = ISorbettoFragola(want).userInfo(address(this));
        ISorbettoFragola(want).collectFees(amount0, amount1);

        uint256 _token0 = IERC20(token0).balanceOf(address(this));
        uint256 _token1 = IERC20(token1).balanceOf(address(this));

        if (_token0 > 0 && _token1 > 0) {
            // 10% is locked up for future gov
            uint256 _keepToken0 = _token0.mul(keepReward).div(keepRewardMax);
            IERC20(token0).safeTransfer(
                IController(controller).treasury(),
                _keepToken0
            );

            uint256 _keepToken1 = _token1.mul(keepReward).div(keepRewardMax);
            IERC20(token1).safeTransfer(
                IController(controller).treasury(),
                _keepToken1
            );

            _token0 = IERC20(token0).balanceOf(address(this));
            _token1 = IERC20(token1).balanceOf(address(this));

            ISorbettoFragola(want).deposit(_token0, _token1);

            // Donates DUST
            IERC20(token0).transfer(
                IController(controller).treasury(),
                IERC20(token0).balanceOf(address(this))
            );
            IERC20(token1).safeTransfer(
                IController(controller).treasury(),
                IERC20(token1).balanceOf(address(this))
            );
        }

        // We want to get back SUSHI LP tokens
        _distributePerformanceFeesAndDeposit();
    }
}
