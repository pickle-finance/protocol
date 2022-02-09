// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-oxd-lp-farm-base.sol";

contract StrategyOxdLqdr is StrategyOxdFarmBase {
    // Token addresses
    address public lqdr = 0x10b620b2dbAC4Faa7D7FFD71Da486f5D44cd86f9;
    uint256 public lqdr_poolId = 9;
    // Spiritswap
    address spiritRouter = 0x16327E3FbDaCA3bcF7E38F5Af2599D2DDc33aE52;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyOxdFarmBase(
            lqdr,
            lqdr_poolId,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        swapRoutes[wftm] = [oxd, usdc, wftm];
        swapRoutes[lqdr] = [wftm, lqdr];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyOxdLqdr";
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

            _swapSushiswapWithRouter(swapRoutes[wftm], _oxd, sushiRouter);
            uint256 _wftm = IERC20(wftm).balanceOf(address(this));

            _swapSushiswapWithRouter(swapRoutes[lqdr], _wftm, spiritRouter);
        }

        _distributePerformanceFeesAndDeposit();
    }

    function _swapSushiswapWithRouter(
        address[] memory path,
        uint256 _amount,
        address router
    ) internal {
        require(path[1] != address(0));

        IERC20(path[0]).safeApprove(router, 0);
        IERC20(path[0]).safeApprove(router, _amount);
        UniswapRouterV2(router).swapExactTokensForTokens(
            _amount,
            0,
            path,
            address(this),
            block.timestamp.add(60)
        );
    }
}
