pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxTime is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 4;

    // Token addresses
    address public png_avax_time_lp = 0x2F151656065E1d1bE83BD5b6F5e7509b59e6512D;
    address public time = 0xb54f16fB19478766A268F172C9480f8da1a7c9C3;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_time_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}

    // **** State Mutations ****

    function harvest() public override onlyBenevolent {
        // Collects Png tokens
        IMiniChef(miniChef).harvest(poolId, address(this));

        uint256 _png = IERC20(png).balanceOf(address(this));
        if (_png > 0) {
            // 10% is sent to treasury
            uint256 _keep = _png.mul(keep).div(keepMax);
            if (_keep > 0) {
                _takeFeePngToSnob(_keep);
            }

            _png = IERC20(png).balanceOf(address(this));

            IERC20(png).safeApprove(pangolinRouter, 0);
            IERC20(png).safeApprove(pangolinRouter, _png);

            _swapPangolin(png, wavax, _png);     
        }

        // Swap half WAVAX for TIME
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            _swapPangolin(wavax, time, _wavax.div(2));
        }

        // Adds in liquidity for AVAX/TIME
        _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _time = IERC20(time).balanceOf(address(this));

        if (_wavax > 0 && _time > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(time).safeApprove(pangolinRouter, 0);
            IERC20(time).safeApprove(pangolinRouter, _time);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                time,
                _wavax,
                _time,
                0,
                0,
                address(this),
                now + 60
            );

            _wavax = IERC20(wavax).balanceOf(address(this));
            _time = IERC20(time).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_time > 0){
                IERC20(time).safeTransfer(
                    IController(controller).treasury(),
                    _time
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxTime";
    }
}