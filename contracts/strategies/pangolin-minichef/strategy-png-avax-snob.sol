pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxSnobLp is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 22;

    // Token addresses
    address public png_avax_snob_lp = 0xa1C2c3B6b120cBd4Cec7D2371FFd4a931A134A32;
    address public snob = 0xC38f41A296A4493Ff429F1238e030924A1542e50;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_snob_lp,
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

        // Swap half WAVAX for SNOB
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            _swapPangolin(wavax, snob, _wavax.div(2));
        }

        // Adds in liquidity for AVAX/SNOB
        _wavax = IERC20(wavax).balanceOf(address(this));

        uint256 _snob = IERC20(snob).balanceOf(address(this));

        if (_wavax > 0 && _snob > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(snob).safeApprove(pangolinRouter, 0);
            IERC20(snob).safeApprove(pangolinRouter, _snob);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                snob,
                _wavax,
                _snob,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _wavax = IERC20(wavax).balanceOf(address(this));
            _snob = IERC20(snob).balanceOf(address(this));
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_snob > 0){
                IERC20(snob).safeTransfer(
                    IController(controller).treasury(),
                    _snob
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxSnobLp";
    }
}