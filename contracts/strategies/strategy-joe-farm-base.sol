// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../interfaces/masterchefjoev2.sol";
import "../interfaces/joe-rewarder.sol";
import "../interfaces/joe.sol";

abstract contract StrategyJoeFarmBase is StrategyBase {
    // Token addresses
    address public constant joe = 0x6e84a6216eA6dACC71eE8E6b0a5B7322EEbC0fDd;
    address public constant joeRouter = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;

    address public constant masterChefJoeV2 = 0xd6a4F121CA35509aF06A0Be99093d08462f53052;

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
        (uint256 amount, ) = IMasterChefJoeV2(masterChefJoeV2).userInfo(
            poolId,
            address(this)
        );
        return amount;
    }

    // Updated based on cryptofish's recommendation
    function getHarvestable() external view returns (uint256, uint256) {
        (uint256 pendingJoe, , , uint256 pendingBonusToken) = IMasterChefJoeV2(
            masterChefJoeV2
        ).pendingTokens(poolId, address(this));
        return (pendingJoe, pendingBonusToken);
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(masterChefJoeV2, 0);
            IERC20(want).safeApprove(masterChefJoeV2, _want);
            IMasterChefJoeV2(masterChefJoeV2).deposit(poolId, _want);
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IMasterChefJoeV2(masterChefJoeV2).withdraw(poolId, _amount);
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

    function _takeFeeJoeToSnob(uint256 _keep) internal {
        address[] memory path = new address[](3);
        path[0] = joe;
        path[1] = wavax;
        path[2] = snob;
        IERC20(joe).safeApprove(joeRouter, 0);
        IERC20(joe).safeApprove(joeRouter, _keep);
        _swapTraderJoeWithPath(path, _keep);
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
}
