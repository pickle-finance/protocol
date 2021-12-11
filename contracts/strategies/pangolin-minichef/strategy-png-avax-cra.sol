pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxCraLp is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 40;

    // Token addresses
    address public png_avax_cra_lp = 0x960FA242468746C59BC32513E2E1e1c24FDFaF3F;
    address public cra = 0xA32608e873F9DdEF944B24798db69d80Bbb4d1ed;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_cra_lp,
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

        // Swap half WAVAX for CRA
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            _swapPangolin(wavax, cra, _wavax.div(2));
        }

        // Adds in liquidity for AVAX/CRA
        _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _cra = IERC20(cra).balanceOf(address(this));

        if (_wavax > 0 && _cra > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(cra).safeApprove(pangolinRouter, 0);
            IERC20(cra).safeApprove(pangolinRouter, _cra);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                cra,
                _wavax,
                _cra,
                0,
                0,
                address(this),
                now + 60
            );

            _wavax = IERC20(wavax).balanceOf(address(this));
            _cra = IERC20(cra).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_cra > 0){
                IERC20(cra).safeTransfer(
                    IController(controller).treasury(),
                    _cra
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxCraLp";
    }
}