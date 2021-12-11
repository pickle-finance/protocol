pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxXavaLp is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 18;

    // Token addresses
    address public png_avax_xava_lp = 0x42152bDD72dE8d6767FE3B4E17a221D6985E8B25;
    address public xava = 0xd1c3f94DE7e5B45fa4eDBBA472491a9f4B166FC4;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_xava_lp,
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

        // Swap half WAVAX for XAVA
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            _swapPangolin(wavax, xava, _wavax.div(2));
        }

        // Adds in liquidity for AVAX/XAVA
        _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _xava = IERC20(xava).balanceOf(address(this));

        if (_wavax > 0 && _xava > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(xava).safeApprove(pangolinRouter, 0);
            IERC20(xava).safeApprove(pangolinRouter, _xava);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                xava,
                _wavax,
                _xava,
                0,
                0,
                address(this),
                now + 60
            );
            
            _wavax = IERC20(wavax).balanceOf(address(this));
            _xava = IERC20(xava).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_xava > 0){
                IERC20(xava).safeTransfer(
                    IController(controller).treasury(),
                    _xava
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxXavaLp";
    }
}