// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-oxd-lp-farm-base.sol";

contract StrategyOxdTomb is StrategyOxdFarmBase {
    // Token addresses
    address public tomb = 0x6c021Ae822BEa943b2E66552bDe1D2696a53fbB7;
    uint256 public tomb_poolId = 12;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyOxdFarmBase(
            tomb,
            tomb_poolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[tomb] = [oxd, usdc, wftm, tomb];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyOxdTomb";
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

            _swapSushiswapWithPath(swapRoutes[tomb], _oxd);
        }

        _distributePerformanceFeesAndDeposit();
    }
}
