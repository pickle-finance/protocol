pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxWowLp is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 32;

    // Token addresses
    address public png_avax_wow_lp = 0x5085678755446F839B1B575cB3d1b6bA85C65760;
    address public wow = 0xA384Bc7Cdc0A93e686da9E7B8C0807cD040F4E0b;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_wow_lp,
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
            IERC20(png).safeApprove(pangolinRouter, _png.sub(_keep));

            _swapPangolin(png, wavax, _png);     
        }

        // Swap half WAVAX for WOW
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            _swapPangolin(wavax, wow, _wavax.div(2));
        }

        // Adds in liquidity for AVAX/WOW
        _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _wow = IERC20(wow).balanceOf(address(this));

        if (_wavax > 0 && _wow > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(wow).safeApprove(pangolinRouter, 0);
            IERC20(wow).safeApprove(pangolinRouter, _wow);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                wow,
                _wavax,
                _wow,
                0,
                0,
                address(this),
                now + 60
            );

            _wavax = IERC20(wavax).balanceOf(address(this));
            _wow = IERC20(wow).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_wow > 0){
                IERC20(wow).safeTransfer(
                    IController(controller).treasury(),
                    _wow
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxWowLp";
    }
}