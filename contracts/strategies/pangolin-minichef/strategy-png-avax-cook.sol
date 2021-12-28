pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxCook is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 51;

    // Token addresses
    address public png_avax_cook_lp = 0xf7FF4fb01c3c1Ab0128A79953CD8B47526292FB2;
    address public cook = 0x637afeff75ca669fF92e4570B14D6399A658902f;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_cook_lp,
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

        // Swap half WAVAX for COOK
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            _swapPangolin(wavax, cook, _wavax.div(2));
        }

        // Adds in liquidity for AVAX/COOK
        _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _cook = IERC20(cook).balanceOf(address(this));

        if (_wavax > 0 && _cook > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(cook).safeApprove(pangolinRouter, 0);
            IERC20(cook).safeApprove(pangolinRouter, _cook);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                cook,
                _wavax,
                _cook,
                0,
                0,
                address(this),
                now + 60
            );

            _wavax = IERC20(wavax).balanceOf(address(this));
            _cook = IERC20(cook).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_cook > 0){
                IERC20(cook).safeTransfer(
                    IController(controller).treasury(),
                    _cook
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxCook";
    }
}