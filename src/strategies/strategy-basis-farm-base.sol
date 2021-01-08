// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-staking-rewards-base.sol";

abstract contract StrategyBasisFarmBase is StrategyStakingRewardsBase {
    // Token addresses
    address public bas = 0xa7ED29B253D8B4E3109ce07c80fc570f81B63696;
    address public dai = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    // DAI/<token1> pair
    address public token1;

    // How much BAS tokens to keep?
    uint256 public keepBAS = 0;
    uint256 public constant keepBASMax = 10000;

    constructor(
        address _token1,
        address _rewards,
        address _lp,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyStakingRewardsBase(
            _rewards,
            _lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        token1 = _token1;
    }

    // **** Setters ****

    function setKeepBAS(uint256 _keepBAS) external {
        require(msg.sender == timelock, "!timelock");
        keepBAS = _keepBAS;
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But ETH is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.
        address[] memory path = new address[](2);

        // Collects BAS tokens
        IStakingRewards(rewards).getReward();
        uint256 _bas = IERC20(bas).balanceOf(address(this));
        if (_bas > 0) {
            // 10% is locked up for future gov
            uint256 _keepBAS = _bas.mul(keepBAS).div(keepBASMax);
            IERC20(bas).safeTransfer(
                IController(controller).treasury(),
                _keepBAS
            );
            path[0] = bas;
            path[1] = dai;
            _swapUniswapWithPath(path, _bas.sub(_keepBAS));
        }

        // Swap half DAI for token
        uint256 _dai = IERC20(dai).balanceOf(address(this));
        if (_dai > 0) {
            path[0] = dai;
            path[1] = token1;
            _swapUniswapWithPath(path, _dai.div(2));
        }

        // Adds in liquidity for DAI/Token
        _dai = IERC20(dai).balanceOf(address(this));
        uint256 _token1 = IERC20(token1).balanceOf(address(this));
        if (_dai > 0 && _token1 > 0) {
            IERC20(dai).safeApprove(univ2Router2, 0);
            IERC20(dai).safeApprove(univ2Router2, _dai);

            IERC20(token1).safeApprove(univ2Router2, 0);
            IERC20(token1).safeApprove(univ2Router2, _token1);

            UniswapRouterV2(univ2Router2).addLiquidity(
                dai,
                token1,
                _dai,
                _token1,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(dai).transfer(
                IController(controller).treasury(),
                IERC20(dai).balanceOf(address(this))
            );
            IERC20(token1).safeTransfer(
                IController(controller).treasury(),
                IERC20(token1).balanceOf(address(this))
            );
        }

        // We want to get back BAS LP tokens
        _distributePerformanceFeesAndDeposit();
    }
}
