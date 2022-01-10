// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../interfaces/masterchefaxialv2.sol";
import "../interfaces/axial-rewarder.sol";
import "../interfaces/joe.sol";
import "../interfaces/wavax.sol";

abstract contract StrategyAxialFarmBase is StrategyBase {
    // Token addresses
    address public constant axial = 0xcF8419A615c57511807236751c0AF38Db4ba3351;
    address public constant joeRouter = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;
    address public constant masterChefAxialV3 = 0x958C0d0baA8F220846d3966742D4Fb5edc5493D3;

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
        (uint256 amount, ) = IMasterChefAxialV2(masterChefAxialV3).userInfo(
            poolId,
            address(this)
        );
        return amount;
    }

     receive() external payable {}

    // Updated based on cryptofish's recommendation
    function getHarvestable() external view returns (uint256, uint256) {
        (uint256 pendingJoe, , , uint256 pendingBonusToken) = IMasterChefAxialV2(
            masterChefAxialV3
        ).pendingTokens(poolId, address(this));
        return (pendingJoe, pendingBonusToken);
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(masterChefAxialV3, 0);
            IERC20(want).safeApprove(masterChefAxialV3, _want);
            IMasterChefAxialV2(masterChefAxialV3).deposit(poolId,_want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IMasterChefAxialV2(masterChefAxialV3).withdraw(poolId, _amount);
        return _amount;
    }

    function _swapTraderJoe(
        address _from,
        address _to,
        uint256 _amount
    ) internal {
        require(_to != address(0));

        address[] memory path;

        if (_from == wavax || _to == wavax) {
            path = new address[](2);
            path[0] = _from;
            path[1] = _to;
        } else {
            path = new address[](3);
            path[0] = _from;
            path[1] = wavax;
            path[2] = _to;
        }

        IJoeRouter(joeRouter).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            now.add(60)
        );
    }

    function _swapTraderJoeWithPath(address[] memory path, uint256 _amount)
        internal
    {
        require(path[1] != address(0));

        IJoeRouter(joeRouter).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            now.add(60)
        );
    }

    function _takeFeeAxialToSnob(uint256 _keep) internal {
        address[] memory path = new address[](3);
        path[0] = axial;
        path[1] = wavax;
        path[2] = snob;
        IERC20(axial).safeApprove(joeRouter, 0);
        IERC20(axial).safeApprove(joeRouter, _keep);
        _swapTraderJoeWithPath(path, _keep);
        uint256 _snob = IERC20(snob).balanceOf(address(this));
        uint256 _share = _snob.mul(revenueShare).div(revenueShareMax);
        IERC20(snob).safeTransfer(feeDistributor, _share);
        IERC20(snob).safeTransfer(
            IController(controller).treasury(),
            _snob.sub(_share)
        );
    }
}
