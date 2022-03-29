// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-base.sol"; 
import "../../interfaces/ecd.sol";
import "../../interfaces/wavax.sol";

/// @notice This is the base strategy contract for Echidna's Strategies
abstract contract StrategyEcdFarmBase is StrategyJoeBase {
    // Token addresses 
    address public constant ptp = 0x22d4002028f537599bE9f666d1c4Fa138522f9c8; 
    address public constant ecd = 0xeb8343D5284CaEc921F035207ca94DB6BAaaCBcd;
   
    address public staking; 
    uint256 poolId; 
   
    constructor(
        address _staking, 
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
        staking = _staking;
    }

    /// @notice returns the balance of the want token being staked
    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, ) = IMasterChef(staking).userInfo(
            poolId, 
            address(this)
        ); 
        return amount;
    }

    /// @notice returns earned ECD rewards ready for harvest
    function getHarvestable() external view returns (uint256) {
       return IMasterChef(staking).pendingEcd(poolId, address(this));
    }

    // **** Setters ****
    /// @notice deposits want token and stakes in order to gain ecd
    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).approve(staking, 0);
            IERC20(want).approve(staking, _want);
            IMasterChef(staking).deposit(poolId, _want);
        }
    }

    /// @notice withdraws some amount from MasterChef
    /// @param _amount the amount of the want token we want to withdraw
    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
      IMasterChef(staking).withdraw(poolId, _amount);
      return _amount;
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