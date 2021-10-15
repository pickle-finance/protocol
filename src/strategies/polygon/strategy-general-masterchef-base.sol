// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../../interfaces/masterchef.sol";

abstract contract StrategyGeneralMasterChefBase is StrategyBase {
    // Token addresses
    address public masterchef;
    address public rewardToken;

    address public token0;
    address public token1;

    // How much TITAN tokens to keep?
    uint256 public keepReward = 0;
    uint256 public constant keepRewardMax = 10000;

    // pool deposit fee
    uint256 public depositFee = 0;

    uint256 public poolId;
    mapping (address => address[]) public uniswapRoutes;

    constructor(
        address _rewardToken,
        address _masterchef,
        address _token0,
        address _token1,
        uint256 _poolId,
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
        poolId = _poolId;
        token0 = _token0;
        token1 = _token1;
        rewardToken = _rewardToken;
        masterchef = _masterchef;
    }
    
    function balanceOfPool() public override view returns (uint256) {
        (uint256 amount, ) = IMasterchef(masterchef).userInfo(poolId, address(this));
        return amount;
    }

    function getHarvestable() external virtual view returns (uint256) {
        uint256 _pendingReward = IMasterchef(masterchef).pendingReward(poolId, address(this));
        return _pendingReward;
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(masterchef, 0);
            IERC20(want).safeApprove(masterchef, _want);
            IMasterchef(masterchef).deposit(poolId, _want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IMasterchef(masterchef).withdraw(poolId, _amount);
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
        IMasterchef(masterchef).withdraw(poolId, 0);
        uint256 _rewardBalance = IERC20(rewardToken).balanceOf(address(this));
        if (_rewardBalance > 0) {
            // 10% is locked up for future gov
            uint256 _keepReward = _rewardBalance.mul(keepReward).div(keepRewardMax);
            IERC20(rewardToken).safeApprove(IController(controller).treasury(), 0);
            IERC20(rewardToken).safeApprove(IController(controller).treasury(), _keepReward);
            IERC20(rewardToken).safeTransfer(
                IController(controller).treasury(),
                _keepReward
            );
        }
        
        uint256 remainingRewardBalance = IERC20(rewardToken).balanceOf(address(this));

        if (remainingRewardBalance == 0) {
          return;
        }
        
        // allow Uniswap to sell our reward
        IERC20(rewardToken).safeApprove(sushiRouter, 0);
        IERC20(rewardToken).safeApprove(sushiRouter, remainingRewardBalance);
        
        uint256 toToken0 = remainingRewardBalance.div(2);
        uint256 toToken1 = remainingRewardBalance.sub(toToken0);

        uint256 token0Amount;
        // we can accept 1 as minimum because this is called only by a trusted role
        uint256 amountOutMin = 1;

        if (uniswapRoutes[token0].length > 1) {
            // if we need to liquidate the token0
            UniswapRouterV2(sushiRouter).swapExactTokensForTokens(
                toToken0,
                amountOutMin,
                uniswapRoutes[token0],
                address(this),
                block.timestamp
            );
            token0Amount = IERC20(token0).balanceOf(address(this));
        } else {
            // otherwise we assume token0 is the reward token itself
            token0Amount = toToken0;
        }

        uint256 token1Amount;

        if (uniswapRoutes[token1].length > 1) {
            // sell reward token to token1
            UniswapRouterV2(sushiRouter).swapExactTokensForTokens(
                toToken1,
                amountOutMin,
                uniswapRoutes[token1],
                address(this),
                block.timestamp
            );
            token1Amount = IERC20(token1).balanceOf(address(this));
        } else {
            token1Amount = toToken1;
        }

        if (token0Amount > 0 && token1Amount > 0) {
            IERC20(token0).safeApprove(sushiRouter, 0);
            IERC20(token0).safeApprove(sushiRouter, token0Amount);
            IERC20(token1).safeApprove(sushiRouter, 0);
            IERC20(token1).safeApprove(sushiRouter, token1Amount);

            UniswapRouterV2(sushiRouter).addLiquidity(
                token0,
                token1,
                token0Amount,
                token1Amount,
                0,
                0,
                address(this),
                now + 60
            );

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
