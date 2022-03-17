// SPDX-License-Identifier: MIT
pragma solidity ^0.6.7;

import "../strategy-vvs-farm-base.sol";

contract StrategyVvsTonicLp is StrategyVVSFarmBase {
    uint256 public vvs_tonic_poolId = 19;

    // Token addresses
    address public vvs_tonic_lp = 0xA922530960A1F94828A7E132EC1BA95717ED1eab;
    address public tonic = 0xDD73dEa10ABC2Bff99c60882EC5b2B81Bb1Dc5B2;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyVVSFarmBase(
            vvs_tonic_poolId,
            vvs_tonic_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {
        uniswapRoutes[tonic] = [vvs, tonic];
        uniswapRoutes[vvs] = [tonic, vvs];
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyVvsTonicLp";
    }

    function harvest() public override {
        IVvsChef(vvsChef).deposit(poolId, 0);
        uint256 _tonic = IERC20(tonic).balanceOf(address(this));

        // Swap all tonic to vvs
        if (_tonic > 0) {
            _swapSushiswapWithPath(uniswapRoutes[vvs], _tonic);
        }

        uint256 _vvs = IERC20(vvs).balanceOf(address(this));

        uint256 _keepVVS = _vvs.mul(keepVVS).div(keepVVSMax);
        IERC20(vvs).safeTransfer(IController(controller).treasury(), _keepVVS);

        _vvs = _vvs.sub(_keepVVS);

        if (_vvs > 0) {
            _swapSushiswapWithPath(uniswapRoutes[tonic], _vvs.div(2));
        }

        // Adds in liquidity for token0/token1
        uint256 _token0 = IERC20(token0).balanceOf(address(this));
        uint256 _token1 = IERC20(token1).balanceOf(address(this));

        if (_token0 > 0 && _token1 > 0) {
            IERC20(token0).safeApprove(sushiRouter, 0);
            IERC20(token0).safeApprove(sushiRouter, _token0);
            IERC20(token1).safeApprove(sushiRouter, 0);
            IERC20(token1).safeApprove(sushiRouter, _token1);

            UniswapRouterV2(sushiRouter).addLiquidity(
                token0,
                token1,
                _token0,
                _token1,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            IERC20(token0).transfer(
                IController(controller).treasury(),
                IERC20(token0).balanceOf(address(this))
            );
            IERC20(token1).safeTransfer(
                IController(controller).treasury(),
                IERC20(token1).balanceOf(address(this))
            );
        }

        _distributePerformanceFeesAndDeposit();
    }
}
