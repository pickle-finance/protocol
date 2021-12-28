pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxSpore is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 29;

    // Token addresses
    address public png_avax_spore_lp = 0x0a63179a8838b5729E79D239940d7e29e40A0116;
    address public spore = 0x6e7f5C0b9f4432716bDd0a77a3601291b9D9e985;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_spore_lp,
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

        // Swap half WAVAX for SPORE
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            _swapPangolin(wavax, spore, _wavax.div(2));
        }

        // Adds in liquidity for AVAX/SPORE
        _wavax = IERC20(wavax).balanceOf(address(this));        
        uint256 _spore = IERC20(spore).balanceOf(address(this));
        
        if (_wavax > 0 && _spore > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(spore).safeApprove(pangolinRouter, 0);
            IERC20(spore).safeApprove(pangolinRouter, _spore);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                spore,
                _wavax,
                _spore,
                0,
                0,
                address(this),
                now + 60
            );

            _wavax = IERC20(wavax).balanceOf(address(this));
            _spore = IERC20(spore).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_spore > 0){
                IERC20(spore).safeTransfer(
                    IController(controller).treasury(),
                    _spore
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxSpore";
    }
}