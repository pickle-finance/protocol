// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../interfaces/masterchefv2.sol";
import "../interfaces/masterchefv2-rewarder.sol";

abstract contract StrategyJoeFarmBase is StrategyBase {
    // Token addresses
    address public constant joe = 0x6B3595068778DD592e39A122f4f5a5cF09C90fE2;
    address public constant joeRouter = 0x60aE616a2155Ee3d9A68541Ba4544862310933d4;

    address public constant masterChefV2 = 0xd6a4F121CA35509aF06A0Be99093d08462f53052;

    uint256 public poolId;

    // How much PNG tokens to keep?
    uint256 public keepJOE = 0;
    uint256 public constant keepJOEMax = 10000;

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
        (uint256 amount, ) =
            IMasterChefV2(masterChefV2).userInfo(poolId, address(this));
        return amount;
    }

    function getHarvestable() external view returns (uint256, uint256) {
      uint256 _pendingSushi = IMasterChefV2(masterChefV2).pendingSushi(poolId, address(this));
      IMasterChefV2Rewarder rewarder = IMasterChefV2Rewarder(IMasterChefV2(masterChefV2).rewarder(poolId));
      (, uint256[] memory _rewardAmounts) = rewarder.pendingTokens(poolId, address(this), 0);

      uint256 _pendingReward;
      if (_rewardAmounts.length > 0) {
          _pendingReward = _rewardAmounts[0];
      }
      return (_pendingSushi, _pendingReward);
    }

    // **** Setters ****
    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(masterChefV2, 0);
            IERC20(want).safeApprove(masterChefV2, _want);
            IMasterChefV2(masterChefV2).deposit(poolId, _want, address(this));
        }
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IMasterChefV2(masterChefV2).withdraw(poolId, _amount, address(this));
        return _amount;
    }
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

    function _swapTraderJoeWithPath(
        address[] memory path,
        uint256 _amount
    ) internal {
        require(path[1] != address(0));

        IJoeRouter(joeRouter).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            now.add(60)
        );
    }