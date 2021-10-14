// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../interfaces/fox-staking-rewards.sol";

abstract contract StrategyFoxFarmBase is StrategyBase {
    // Token addresses
    address public constant stakingRewards = 0xc54B9F82C1c54E9D4d274d633c7523f2299c42A0;
    address public constant fox = 0xc770EEfAd204B5180dF6a14Ee197D99d808ee52d;

    // WETH/<token1> pair
    address public token1;

    // How much FOX tokens to keep?
    uint256 public keepFOX = 0;
    uint256 public constant keepFOXMax = 10000;

    constructor(
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
    }
    
    function balanceOfPool() public override view returns (uint256) {
        return IFoxStakingRewards(stakingRewards).balanceOf(address(this));
    }

    function getHarvestable() external view returns (uint256) {
        return IFoxStakingRewards(stakingRewards).earned(address(this));
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(stakingRewards, 0);
            IERC20(want).safeApprove(stakingRewards, _want);
            IFoxStakingRewards(stakingRewards).stake(_want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IFoxStakingRewards(stakingRewards).withdraw(_amount);
        return _amount;
    }

    // **** Setters ****

    function setKeepFOX(uint256 _keepFOX) external {
        require(msg.sender == timelock, "!timelock");
        keepFOX = _keepFOX;
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Collects FOX tokens
        IFoxStakingRewards(stakingRewards).getReward();
        uint256 _fox = IERC20(fox).balanceOf(address(this));
        if (_fox > 0) {
            // 10% is locked up for future gov
            uint256 _keepFOX = _fox.mul(keepFOX).div(keepFOXMax);
            IERC20(fox).safeTransfer(
                IController(controller).treasury(),
                _keepFOX
            );
            uint256 _swap = _fox.sub(_keepFOX);
            IERC20(fox).safeApprove(univ2Router2, 0);
            IERC20(fox).safeApprove(univ2Router2, _swap);
            _swapUniswap(fox, weth, _swap);
        }

        // Swap half WETH for token1
        uint256 _weth = IERC20(weth).balanceOf(address(this));
        if (_weth > 0) {
            IERC20(weth).safeApprove(univ2Router2, 0);
            IERC20(weth).safeApprove(univ2Router2, _weth);
            _swapUniswap(weth, token1, _weth.div(2));
        }

        // Adds in liquidity for ETH/token1
        _weth = IERC20(weth).balanceOf(address(this));
        uint256 _token1 = IERC20(token1).balanceOf(address(this));
        if (_weth > 0 && _token1 > 0) {
            IERC20(weth).safeApprove(univ2Router2, 0);
            IERC20(weth).safeApprove(univ2Router2, _weth);
            IERC20(token1).safeApprove(univ2Router2, 0);
            IERC20(token1).safeApprove(univ2Router2, _token1);

            UniswapRouterV2(univ2Router2).addLiquidity(
                weth,
                token1,
                _weth,
                _token1,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(weth).transfer(
                IController(controller).treasury(),
                IERC20(weth).balanceOf(address(this))
            );
            IERC20(token1).safeTransfer(
                IController(controller).treasury(),
                IERC20(token1).balanceOf(address(this))
            );
        }

        // We want to get back FOX LP tokens
        _distributePerformanceFeesAndDeposit();
    }
}
