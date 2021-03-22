// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-alcx-farm-base.sol";

contract StrategySushiEthAlcxLp is StrategyAlchemixFarmBase {

    uint256 public sushi_alcx_poolId = 2;

    address public sushi_eth_alcx_lp = 0xC3f279090a47e80990Fe3a9c30d24Cb117EF91a8;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyAlchemixFarmBase(
            sushi_alcx_poolId,
            sushi_eth_alcx_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        IERC20(alcx).approve(sushiRouter, uint(-1));
    }

    // **** Views ****

    function getName() external override pure returns (string memory) {
        return "StrategySushiEthAlcxLp";
    }

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Collects Alcx tokens
        IStakingPools(stakingPool).claim(poolId);
        uint256 _alcx = IERC20(alcx).balanceOf(address(this));
        if (_alcx > 0) {
            // 10% is locked up for future gov
            uint256 _keepAlcx = _alcx.mul(keepAlcx).div(keepAlcxMax);
            IERC20(alcx).safeTransfer(
                IController(controller).treasury(),
                _keepAlcx
            );
            uint256 _amount = _alcx.sub(_keepAlcx);
            _swapSushiswap(alcx, weth, _amount.div(2));
        }

        // Adds in liquidity for WETH/ALCX
        uint256 _weth = IERC20(weth).balanceOf(address(this));
        
        _alcx = IERC20(alcx).balanceOf(address(this));

        if (_weth > 0 && _alcx > 0) {
            IERC20(weth).safeApprove(sushiRouter, 0);
            IERC20(weth).safeApprove(sushiRouter, _weth);

            IERC20(alcx).safeApprove(sushiRouter, 0);
            IERC20(alcx).safeApprove(sushiRouter, _alcx);

            UniswapRouterV2(sushiRouter).addLiquidity(
                weth,
                alcx,
                _weth,
                _alcx,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(weth).transfer(
                IController(controller).treasury(),
                IERC20(weth).balanceOf(address(this))
            );
            IERC20(alcx).safeTransfer(
                IController(controller).treasury(),
                IERC20(alcx).balanceOf(address(this))
            );
        }
        
        _distributePerformanceFeesAndDeposit();
    }

    function _withdrawSome(uint256 _amount)
        internal
        override
        returns (uint256)
    {
        IStakingPools(stakingPool).withdraw(poolId, _amount);
        return _amount;
    }    
}
