// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-oxd-xtoken-farm-base.sol";

contract StrategyOxdXtarot is StrategyOxdXtokenFarmBase {
    // Token addresses
    address public xtarot = 0x74D1D2A851e339B8cB953716445Be7E8aBdf92F4;
    address public tarot = 0xC5e2B037D30a390e62180970B3aa4E91868764cD;
    uint256 public xtarot_poolId = 10;

    address public tarotVault = 0x3E9F34309B2f046F4f43c0376EFE2fdC27a10251;
    address public toBorrowable = 0xE0d10cEfc6CDFBBde41A12C8BBe9548587568329;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyOxdXtokenFarmBase(
            xtarot,
            tarot,
            xtarot_poolId,
            "",
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[tarot] = [oxd, usdc, wftm, tarot];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyOxdXtarot";
    }

    function harvest() public override {
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

            if (swapRoutes[underlying].length > 1) {
                _swapSushiswapWithPath(swapRoutes[underlying], _oxd);
            }
        }

        // Stakes in Xtoken contract
        uint256 _underlying = IERC20(underlying).balanceOf(address(this));
        IERC20(underlying).safeApprove(tarotVault, 0);
        IERC20(underlying).safeApprove(tarotVault, _underlying);

        IXtoken(tarotVault).enter(xtarot, _underlying, toBorrowable);
        _distributePerformanceFeesAndDeposit();
    }
}
