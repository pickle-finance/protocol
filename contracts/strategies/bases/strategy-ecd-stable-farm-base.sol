// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-base.sol"; 
import "../../interfaces/ecd.sol";
import "../../interfaces/wavax.sol";

/// @notice This is a base contract for Echidna staking
abstract contract StrategyStableFarmBase is StrategyJoeBase {
    // Token addresses 
    address public constant ptp = 0x22d4002028f537599bE9f666d1c4Fa138522f9c8; 
    address public constant ecd = 0xeb8343D5284CaEc921F035207ca94DB6BAaaCBcd;
   
    address public constant staking = 0x4537398FF971A7037E8414A2A9b6B1646dE91D96;
    address public constant booster = 0x43Cf1FD9260adA2Ec8069Ce7cBD04318B1F9c3FF;

    address public platypusPool = 0x66357dCaCe80431aee0A7507e2E361B7e2402370; 

    address public rewardPool; 
    address public stablepool; 

    uint256 poolId; 
   
    constructor(
        address _rewardPool, 
        address _stablepool, 
        uint256 _poolId,
        address _want,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
    public StrategyJoeBase(
        _want,
        _governance,
        _strategist,
        _controller,
        _timelock
    )
    {
        poolId = _poolId;
        stablepool = _stablepool;
        rewardPool = _rewardPool;
    }
    
    /// @notice returns the balance of the want token being staked
    function balanceOfPool() public view override returns (uint256) {
        return IRewardPool(rewardPool).balanceOf(address(this));
    }

    /// @notice returns earned ECD rewards ready for harvest
    function getHarvestable() external view returns (uint256) {
        return IRewardPool(rewardPool).earned(address(this));
    }

    // **** Setters ****
    /// @notice deposits stable token 
    function deposit() public override {
        // the first deposit would be the stablecoin 
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).approve(staking, 0);
            IERC20(want).approve(staking, _want);
            IDepositZap(staking).deposit(poolId, platypusPool, want, _want, now + 60);
        }

        // the second deposit is the lp-stablecoin pairing
        uint256 _stablewant = IERC20(stablepool).balanceOf(address(this)); 
        if(_stablewant > 0){
            IERC20(stablepool).approve(booster, 0);
            IERC20(stablepool).approve(booster, _stablewant);
            IBooster(booster).deposit(poolId, _stablewant);
        }      
    }

    /// @notice withdraws some amount from the staking contract
    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IBooster(booster).withdraw(poolId, _amount, true);

        IERC20(stablepool).approve(platypusPool, 0);
        IERC20(stablepool).approve(platypusPool, _amount);

        return IPool(platypusPool).withdraw(want, _amount, 0, address(this), now);
    }

    /// @notice takes a fee from any reward token to snob
    function _takeFeeRewardToSnob(uint256 _keep, address reward) internal {
        address[] memory path = new address[](3);
        path[0] = reward;
        path[1] = wavax;
        path[2] = snob;
        IERC20(reward).safeApprove(joeRouter, 0);
        IERC20(reward).safeApprove(joeRouter, _keep);
        _swapTraderJoeWithPath(path, _keep);
        uint256 _snob = IERC20(snob).balanceOf(address(this));
        uint256 _share = _snob.mul(revenueShare).div(revenueShareMax);
        IERC20(snob).safeTransfer(
            feeDistributor,
            _share
        );
        IERC20(snob).safeTransfer(
            IController(controller).treasury(),
            _snob.sub(_share)
        );
    }
}