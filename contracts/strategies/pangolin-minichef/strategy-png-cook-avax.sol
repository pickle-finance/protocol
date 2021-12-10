pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngCookAvaxLp is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 51;

    // Token addresses
    address public Png_COOK_AVAX_lp = 0xf7FF4fb01c3c1Ab0128A79953CD8B47526292FB2;
    address public token1 = 0x637afeff75ca669fF92e4570B14D6399A658902f;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            Png_COOK_AVAX_lp,
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

        // Swap half WAVAX for token
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0 && token1 != png) {
            _swapPangolin(wavax, token1, _wavax.div(2));
        }

        // Adds in liquidity for COOK/AVAX
        _wavax = IERC20(wavax).balanceOf(address(this));

        uint256 _token1 = IERC20(token1).balanceOf(address(this));

        if (_wavax > 0 && _token1 > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(token1).safeApprove(pangolinRouter, 0);
            IERC20(token1).safeApprove(pangolinRouter, _token1);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                token1,
                _wavax,
                _token1,
                0,
                0,
                address(this),
                now + 60
            );

            // Donates DUST
            _wavax = IERC20(wavax).balanceOf(address(this));
            _token1 = IERC20(token1).balanceOf(address(this));
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_token1 > 0){
                IERC20(token1).safeTransfer(
                    IController(controller).treasury(),
                    _token1
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngCookAvaxLp";
    }
}