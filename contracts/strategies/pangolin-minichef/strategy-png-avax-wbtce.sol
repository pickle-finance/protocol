pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxWbtcELp is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 5;

    // Token addresses
    address public png_avax_wbtce_lp = 0x5764b8D8039C6E32f1e5d8DE8Da05DdF974EF5D3;
    address public wbtce = 0x50b7545627a5162F82A992c33b87aDc75187B218;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_wbtce_lp,
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

        // Swap half WAVAX for WBTCe
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            _swapPangolin(wavax, wbtce, _wavax.div(2));
        }

        // Adds in liquidity for AVAX/WBTCe
        _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _wbtce = IERC20(wbtce).balanceOf(address(this));

        if (_wavax > 0 && _wbtce > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(wbtce).safeApprove(pangolinRouter, 0);
            IERC20(wbtce).safeApprove(pangolinRouter, _wbtce);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                wbtce,
                _wavax,
                _wbtce,
                0,
                0,
                address(this),
                now + 60
            );

            _wavax = IERC20(wavax).balanceOf(address(this));
            _wbtce = IERC20(wbtce).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_wbtce > 0){
                IERC20(wbtce).safeTransfer(
                    IController(controller).treasury(),
                    _wbtce
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxWbtcELp";
    }
}