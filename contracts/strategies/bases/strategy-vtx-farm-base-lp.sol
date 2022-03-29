// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-base.sol"; 
import "../../interfaces/vtx.sol";
import "../../interfaces/wavax.sol";

/// @notice This is a base contract for Vector staking
abstract contract StrategyVtxLPFarmBase is StrategyJoeBase {
    // Token addresses 
    address public constant vtx = 0x5817D4F0b62A59b17f75207DA1848C2cE75e7AF4;
    address public constant ptp = 0x22d4002028f537599bE9f666d1c4Fa138522f9c8; 

    address public staking; 
 
    constructor(
        address _staking,
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
        staking = _staking;
    }

    /// @notice returns the balance of the want token being staked
    function balanceOfPool() public view override returns (uint256) { 
        return IMasterChefVTX(staking).depositInfo(want, address(this));
    }

    /// @notice returns earned VTX and the input token ready for harvest
    function getHarvestable() external view returns (uint256, uint256) {
        (uint256 pendingVTX, , ,uint256 pendingPTP) = IMasterChefVTX(staking).pendingTokens(want, address(this), ptp);
        return (pendingVTX, pendingPTP);
    }

    // **** Setters ****
    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).approve(staking, 0);
            IERC20(want).approve(staking, _want);

            IMasterChefVTX(staking).deposit(want, _want);
        }
    }

    /// @notice withdraws some amount from MasterChef
    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IMasterChefVTX(staking).withdraw(want, _amount); 
        return _amount;
    }

    /// @notice takes a fee from any reward token to snob
    function _takeFeeRewardToSnob(uint256 _keep, address reward) internal {
        IERC20(reward).safeApprove(joeRouter, 0);
        IERC20(reward).safeApprove(joeRouter, _keep);
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