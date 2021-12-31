pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxMaxi is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 42;

    // Token addresses
    address public png_avax_maxi_lp = 0xbb700450811a30c5ee0dB80925Cf1BA53dBBd60A;
    address public maxi = 0x7C08413cbf02202a1c13643dB173f2694e0F73f0;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_maxi_lp,
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

        // Swap half WAVAX for MAXI
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            _swapPangolin(wavax, maxi, _wavax.div(2));
        }

        // Adds in liquidity for AVAX/MAXI
        _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _maxi = IERC20(maxi).balanceOf(address(this));

        if (_wavax > 0 && _maxi > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(maxi).safeApprove(pangolinRouter, 0);
            IERC20(maxi).safeApprove(pangolinRouter, _maxi);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                maxi,
                _wavax,
                _maxi,
                0,
                0,
                address(this),
                now + 60
            );

            _wavax = IERC20(wavax).balanceOf(address(this));
            _maxi = IERC20(maxi).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_maxi > 0){
                IERC20(maxi).safeTransfer(
                    IController(controller).treasury(),
                    _maxi
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxMaxi";
    }
}