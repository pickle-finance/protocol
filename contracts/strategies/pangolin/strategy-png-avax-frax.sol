pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxFrax is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 37;

    // Token addresses
    address public png_avax_frax_lp = 0x0CE543c0f81ac9AAa665cCaAe5EeC70861a6b559;
    address public frax = 0xD24C2Ad096400B6FBcd2ad8B24E7acBc21A1da64;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_frax_lp,
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

        // Swap half WAVAX for FRAX
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            _swapPangolin(wavax, frax, _wavax.div(2));
        }

        // Adds in liquidity for AVAX/FRAX
        _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _frax = IERC20(frax).balanceOf(address(this));

        if (_wavax > 0 && _frax > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(frax).safeApprove(pangolinRouter, 0);
            IERC20(frax).safeApprove(pangolinRouter, _frax);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                frax,
                _wavax,
                _frax,
                0,
                0,
                address(this),
                now + 60
            );

            _wavax = IERC20(wavax).balanceOf(address(this));
            _frax = IERC20(frax).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_frax > 0){
                IERC20(frax).safeTransfer(
                    IController(controller).treasury(),
                    _frax
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxFrax";
    }
}