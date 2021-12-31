pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxYak is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 15;

    // Token addresses
    address public png_avax_yak_lp = 0xd2F01cd87A43962fD93C21e07c1a420714Cc94C9;
    address public yak = 0x59414b3089ce2AF0010e7523Dea7E2b35d776ec7;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_yak_lp,
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

        // Swap half WAVAX for YAK
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            _swapPangolin(wavax, yak, _wavax.div(2));
        }

        // Adds in liquidity for AVAX/YAK
        _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _yak = IERC20(yak).balanceOf(address(this));

        if (_wavax > 0 && _yak > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(yak).safeApprove(pangolinRouter, 0);
            IERC20(yak).safeApprove(pangolinRouter, _yak);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                yak,
                _wavax,
                _yak,
                0,
                0,
                address(this),
                now + 60
            );

            _wavax = IERC20(wavax).balanceOf(address(this));
            _yak = IERC20(yak).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_yak > 0){
                IERC20(yak).safeTransfer(
                    IController(controller).treasury(),
                    _yak
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxYak";
    }
}