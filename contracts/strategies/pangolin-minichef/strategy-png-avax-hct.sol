pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxHctLp is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 33;

    // Token addresses
    address public png_avax_hct_lp = 0x0B1efd689eBA7E610955d0FaBd9Ab713a04c3895;
    address public hct = 0x45C13620B55C35A5f539d26E88247011Eb10fDbd;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_hct_lp,
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

        // Swap half WAVAX for HCT
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0 && hct != png) {
            _swapPangolin(wavax, hct, _wavax.div(2));
        }

        // Adds in liquidity for AVAX/HCT
        _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _hct = IERC20(hct).balanceOf(address(this));

        if (_wavax > 0 && _hct > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(hct).safeApprove(pangolinRouter, 0);
            IERC20(hct).safeApprove(pangolinRouter, _hct);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                hct,
                _wavax,
                _hct,
                0,
                0,
                address(this),
                now + 60
            );

            _wavax = IERC20(wavax).balanceOf(address(this));
            _hct = IERC20(hct).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_hct > 0){
                IERC20(hct).safeTransfer(
                    IController(controller).treasury(),
                    _hct
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxHctLp";
    }
}