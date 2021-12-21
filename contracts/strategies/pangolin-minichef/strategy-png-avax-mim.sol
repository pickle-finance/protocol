pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxMimLp is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 52;

    // Token addresses
    address public png_avax_mim_lp = 0x239aAE4AaBB5D60941D7DFFAeaFE8e063C63Ab25;
    address public mim = 0x130966628846BFd36ff31a822705796e8cb8C18D;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_mim_lp,
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

        // Swap half WAVAX for MIM
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            _swapPangolin(wavax, mim, _wavax.div(2));
        }

        // Adds in liquidity for AVAX/MIM
        _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _mim = IERC20(mim).balanceOf(address(this));

        if (_wavax > 0 && _mim > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(mim).safeApprove(pangolinRouter, 0);
            IERC20(mim).safeApprove(pangolinRouter, _mim);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                mim,
                _wavax,
                _mim,
                0,
                0,
                address(this),
                now + 60
            );

            _wavax = IERC20(wavax).balanceOf(address(this));
            _mim = IERC20(mim).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_mim > 0){
                IERC20(mim).safeTransfer(
                    IController(controller).treasury(),
                    _mim
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxMimLp";
    }
}