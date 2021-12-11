pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxTeddyLp is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 27;

    // Token addresses
    address public png_avax_teddy_lp = 0x4F20E367B10674cB45Eb7ede68c33B702E1Be655;
    address public teddy = 0x094bd7B2D99711A1486FB94d4395801C6d0fdDcC;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_teddy_lp,
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

            _swapPangolin(png, wavax, _png.div(2));     
        }

        // Swap half WAVAX for TEDDY
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            _swapPangolin(wavax, teddy, _wavax.div(2));
        }

        // Adds in liquidity for AVAX/TEDDY
        _wavax = IERC20(wavax).balanceOf(address(this));

        uint256 _teddy = IERC20(teddy).balanceOf(address(this));

        if (_wavax > 0 && _teddy > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(teddy).safeApprove(pangolinRouter, 0);
            IERC20(teddy).safeApprove(pangolinRouter, _teddy);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                teddy,
                _wavax,
                _teddy,
                0,
                0,
                address(this),
                now + 60
            );

            _wavax = IERC20(wavax).balanceOf(address(this));
            _teddy = IERC20(teddy).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_teddy > 0){
                IERC20(teddy).safeTransfer(
                    IController(controller).treasury(),
                    _teddy
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxTeddyLp";
    }
}