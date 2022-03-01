// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-oxd-lp-farm-base.sol";

contract StrategyOxdSingle is StrategyOxdFarmBase {
    // Token addresses
    uint256 public oxd_poolId = 14;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyOxdFarmBase(
            oxd,
            oxd_poolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyOxdSingle";
    }

    // **** State Mutations ****
    function harvest() public virtual override {
        // Collects OXD tokens
        IOxdChef(oxdChef).deposit(poolId, 0);
        uint256 _oxd = IERC20(oxd).balanceOf(address(this));

        if (_oxd > 0) {
            uint256 _keepOXD = _oxd.mul(keepOXD).div(keepOXDMax);
            IERC20(oxd).safeTransfer(
                IController(controller).treasury(),
                _keepOXD
            );
            _oxd = _oxd.sub(_keepOXD);
        }

        _distributePerformanceFeesAndDeposit();
    }
}
