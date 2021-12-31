pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxApein is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 16;

    // Token addresses
    address public png_avax_apein_lp = 0x8dEd946a4B891D81A8C662e07D49E4dAee7Ab7d3;
    address public apein = 0x938FE3788222A74924E062120E7BFac829c719Fb;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_apein_lp,
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

        // Swap half WAVAX for APEIN
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            _swapPangolin(wavax, apein, _wavax.div(2));
        }

        // Adds in liquidity for AVAX/APEIN
        _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _apein = IERC20(apein).balanceOf(address(this));

        if (_wavax > 0 && _apein > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(apein).safeApprove(pangolinRouter, 0);
            IERC20(apein).safeApprove(pangolinRouter, _apein);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                apein,
                _wavax,
                _apein,
                0,
                0,
                address(this),
                now + 60
            );

            _wavax = IERC20(wavax).balanceOf(address(this));
            _apein = IERC20(apein).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_apein > 0){
                IERC20(apein).safeTransfer(
                    IController(controller).treasury(),
                    _apein
                );
            }
        }
        
        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxApein";
    }
}