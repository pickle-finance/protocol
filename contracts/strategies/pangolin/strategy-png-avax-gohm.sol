pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxgOhm is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 39;

    // Token addresses
    address public png_avax_gohm_lp = 0xb68F4e8261A4276336698f5b11DC46396cf07A22;
    address public gohm = 0x321E7092a180BB43555132ec53AaA65a5bF84251;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_gohm_lp,
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

        // Swap half WAVAX for GOHM
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            _swapPangolin(wavax, gohm, _wavax.div(2));
        }

        // Adds in liquidity for AVAX/GOHM
        _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _gohm = IERC20(gohm).balanceOf(address(this));

        if (_wavax > 0 && _gohm > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(gohm).safeApprove(pangolinRouter, 0);
            IERC20(gohm).safeApprove(pangolinRouter, _gohm);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                gohm,
                _wavax,
                _gohm,
                0,
                0,
                address(this),
                now + 60
            );

            _wavax = IERC20(wavax).balanceOf(address(this));
            _gohm = IERC20(gohm).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_gohm > 0){
                IERC20(gohm).safeTransfer(
                    IController(controller).treasury(),
                    _gohm
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxgOhm";
    }
}