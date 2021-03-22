// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "./strategy-base.sol";
import "../interfaces/alcx-farm.sol";

abstract contract StrategyAlchemixFarmBase is StrategyBase {
    // Token addresses
    address public constant alcx = 0xdBdb4d16EdA451D0503b854CF79D55697F90c8DF;
    address public constant stakingPool = 0xAB8e74017a8Cc7c15FFcCd726603790d26d7DeCa;

    // How much Alcx tokens to keep?
    uint256 public keepAlcx = 0;
    uint256 public constant keepAlcxMax = 10000;
    
    uint256 public alcxPoolId = 1;

    uint256 public poolId;

    constructor(
        uint256 _poolId,
        address _token,
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyBase(
            _token,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        poolId = _poolId;
    }
    
    function balanceOfPool() public override view returns (uint256) {
        uint256 amount = IStakingPools(stakingPool).getStakeTotalDeposited(address(this), poolId);
        return amount;
    }

    function getHarvestable() public view returns (uint256) {
        return IStakingPools(stakingPool).getStakeTotalUnclaimed(address(this), poolId);
    }

    // **** Setters ****

    function deposit() public override {
        uint256 _want = IERC20(want).balanceOf(address(this));
        if (_want > 0) {
            IERC20(want).safeApprove(stakingPool, 0);
            IERC20(want).safeApprove(stakingPool, _want);
            IStakingPools(stakingPool).deposit(poolId, _want);
        }
    }

    // **** Setters ****

    function setKeepAlcx(uint256 _keepAlcx) external {
        require(msg.sender == timelock, "!timelock");
        keepAlcx = _keepAlcx;
    }
    // can't have harvest function here
}
