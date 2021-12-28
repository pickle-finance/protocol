pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxTusd is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 25;

    // Token addresses
    address public png_avax_tusd_lp = 0xE9DfCABaCA5E45C0F3C151f97900511f3E73Fb47;
    address public tusd = 0x1C20E891Bab6b1727d14Da358FAe2984Ed9B59EB;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_tusd_lp,
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

        // Swap half WAVAX for TUSD
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            _swapPangolin(wavax, tusd, _wavax.div(2));
        }

        // Adds in liquidity for AVAX/TUSD
        _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _tusd = IERC20(tusd).balanceOf(address(this));

        if (_wavax > 0 && _tusd > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(tusd).safeApprove(pangolinRouter, 0);
            IERC20(tusd).safeApprove(pangolinRouter, _tusd);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                tusd,
                _wavax,
                _tusd,
                0,
                0,
                address(this),
                now + 60
            );

            _wavax = IERC20(wavax).balanceOf(address(this));
            _tusd = IERC20(tusd).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_tusd > 0){
                IERC20(tusd).safeTransfer(
                    IController(controller).treasury(),
                    _tusd
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxTusd";
    }
}