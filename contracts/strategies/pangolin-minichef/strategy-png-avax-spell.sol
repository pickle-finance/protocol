pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxSpellLp is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 3;

    // Token addresses
    address public png_avax_spell_lp = 0xD4CBC976E1a1A2bf6F4FeA86DEB3308d68638211;
    address public spell = 0xCE1bFFBD5374Dac86a2893119683F4911a2F7814;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_spell_lp,
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

        // Swap half WAVAX for SPELL
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0 && spell != png) {
            _swapPangolin(wavax, spell, _wavax.div(2));
        }

        // Adds in liquidity for AVAX/SPELL
        _wavax = IERC20(wavax).balanceOf(address(this));

        uint256 _spell = IERC20(spell).balanceOf(address(this));

        if (_wavax > 0 && _spell > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(spell).safeApprove(pangolinRouter, 0);
            IERC20(spell).safeApprove(pangolinRouter, _spell);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                spell,
                _wavax,
                _spell,
                0,
                0,
                address(this),
                now + 60
            );

            _wavax = IERC20(wavax).balanceOf(address(this));
            _spell = IERC20(spell).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_spell > 0){
                IERC20(spell).safeTransfer(
                    IController(controller).treasury(),
                    _spell
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxSpellLp";
    }
}