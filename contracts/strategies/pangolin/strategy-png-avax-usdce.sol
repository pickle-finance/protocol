pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxUsdcE is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 9;

    // Token addresses
    address public png_avax_usdce_lp = 0xbd918Ed441767fe7924e99F6a0E0B568ac1970D9;
    address public usdce = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_usdce_lp,
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

        // Swap half WAVAX for USDCe
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            _swapPangolin(wavax, usdce, _wavax.div(2));
        }

        // Adds in liquidity for AVAX/USDCe
        _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _usdce = IERC20(usdce).balanceOf(address(this));

        if (_wavax > 0 && _usdce > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(usdce).safeApprove(pangolinRouter, 0);
            IERC20(usdce).safeApprove(pangolinRouter, _usdce);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                usdce,
                _wavax,
                _usdce,
                0,
                0,
                address(this),
                now + 60
            );

            _wavax = IERC20(wavax).balanceOf(address(this));
            _usdce = IERC20(usdce).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_usdce > 0){
                IERC20(usdce).safeTransfer(
                    IController(controller).treasury(),
                    _usdce
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxUsdcE";
    }
}