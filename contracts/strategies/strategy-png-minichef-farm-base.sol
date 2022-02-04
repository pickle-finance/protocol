// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../interfaces/minichefpangolin.sol";
import "../interfaces/minichef-rewarder.sol";
import "../interfaces/wavax.sol";

abstract contract StrategyPngMiniChefFarmBase is StrategyBase {
    // Token addresses
    address public constant miniChef = 0x1f806f7C8dED893fd3caE279191ad7Aa3798E928 ;

    uint256 public poolId;

    constructor(
        uint256 _poolId,
        address _lp,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(_lp, _governance, _strategist, _controller, _timelock)
    {
        poolId = _poolId;
    }

    function balanceOfPool() public view override returns (uint256) {
        (uint256 amount, ) = IMiniChef(miniChef).userInfo(
            poolId,
            address(this)
        );
        return amount;
    }

     receive() external payable {}

    // Updated based on cryptofish's recommendation
    function getHarvestable() external view returns (uint256) {
        (uint256 pending) = IMiniChef(
            miniChef
        ).pendingReward(poolId, address(this));
        return (pending);
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(miniChef, 0);
            IERC20(want).safeApprove(miniChef, _want);
            IMiniChef(miniChef).deposit(poolId,_want, address(this));
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IMiniChef(miniChef).withdraw(poolId, _amount, address(this));
        return _amount;
    }


    function _takeFeePngToSnob(uint256 _keep) internal {
        IERC20(png).safeApprove(pangolinRouter, 0);
        IERC20(png).safeApprove(pangolinRouter, _keep);
        _swapPangolin(png, snob, _keep);
        uint _snob = IERC20(snob).balanceOf(address(this));
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
    
    function _swapBaseToToken(uint256 _amount, address token1, address token2) internal {
        address[] memory path = new address[](3);
        path[0] = token1;
        path[1] = wavax;
        path[2] = token2;
        IERC20(token1).safeApprove(pangolinRouter, 0);
        IERC20(token1).safeApprove(pangolinRouter, _amount);
        _swapPangolinWithPath(path, _amount);
    }

    function _takeFeeRewardToSnob(uint256 _keep, address reward) internal {
        address[] memory path = new address[](3);
        path[0] = reward;
        path[1] = wavax;
        path[2] = snob;
        IERC20(reward).safeApprove(pangolinRouter, 0);
        IERC20(reward).safeApprove(pangolinRouter, _keep);
        _swapPangolinWithPath(path, _keep);
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
