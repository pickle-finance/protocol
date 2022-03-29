// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-joe-base.sol"; 
import "../../interfaces/vtx.sol";
import "../../interfaces/wavax.sol";

/// @notice This is a base contract for Vector staking
abstract contract StrategyVtxFarmBase is StrategyJoeBase {
    // Token addresses 
    address public constant vtx = 0x5817D4F0b62A59b17f75207DA1848C2cE75e7AF4;
    address public constant ptp = 0x22d4002028f537599bE9f666d1c4Fa138522f9c8; 

    address public constant TransparentUpgradeableProxy = 0x8B3d9F0017FA369cD8C164D0Cc078bf4cA588aE5;
    address public poolHelper; 
    address public rewarder; 

    constructor(
        address _rewarder, 
        address _poolHelper,
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
        poolHelper = _poolHelper;
        rewarder = _rewarder;
    }

    /// @notice returns the balance of the want token being staked
    function balanceOfPool() public view override returns (uint256) { 
        return IPoolHelper(poolHelper).balance(address(this)); 
    }

    /// @notice returns earned VTX and the input token ready for harvest
    function getHarvestable() external view returns (uint256, uint256) {
        (uint256 VtxAmount, ) = IPoolHelper(poolHelper).earned(want); 
        uint256 PtpAmount = IBaseRewardPool(rewarder).earned(address(this), ptp); 

        return (VtxAmount, PtpAmount);
    }

    // **** Setters ****
    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).approve(TransparentUpgradeableProxy, 0);
            IERC20(want).approve(TransparentUpgradeableProxy, _want);

            IPoolHelper(poolHelper).deposit(_want);
        }
    }

    /// @notice withdraws some amount from staking contract and accounts for slippage
    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IPoolHelper(poolHelper).withdraw(_amount, 0);

        uint256 _balanceOfWant = IERC20(want).balanceOf(address(this)); 
        uint256 _slippage = (_balanceOfWant.mul(10**22)).div(_amount); 
        uint256 _amountWithSlippage = (_amount.mul(_slippage)).div(10**22);

        return _amountWithSlippage;
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