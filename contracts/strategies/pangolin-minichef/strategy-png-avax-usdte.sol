pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngAvaxUsdtE is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 7;

    // Token addresses
    address public png_avax_usdte_lp = 0xe28984e1EE8D431346D32BeC9Ec800Efb643eef4;
    address public usdte = 0xc7198437980c041c805A1EDcbA50c1Ce5db95118;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_avax_usdte_lp,
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

        // Swap half WAVAX for USDTe
        uint256 _wavax = IERC20(wavax).balanceOf(address(this));
        if (_wavax > 0) {
            _swapPangolin(wavax, usdte, _wavax.div(2));
        }

        // Adds in liquidity for AVAX/USDTe
        _wavax = IERC20(wavax).balanceOf(address(this));
        uint256 _usdte = IERC20(usdte).balanceOf(address(this));

        if (_wavax > 0 && _usdte > 0) {
            IERC20(wavax).safeApprove(pangolinRouter, 0);
            IERC20(wavax).safeApprove(pangolinRouter, _wavax);

            IERC20(usdte).safeApprove(pangolinRouter, 0);
            IERC20(usdte).safeApprove(pangolinRouter, _usdte);

            IPangolinRouter(pangolinRouter).addLiquidity(
                wavax,
                usdte,
                _wavax,
                _usdte,
                0,
                0,
                address(this),
                now + 60
            );

            _wavax = IERC20(wavax).balanceOf(address(this));
            _usdte = IERC20(usdte).balanceOf(address(this));
            
            // Donates DUST
            if (_wavax > 0){
                IERC20(wavax).transfer(
                    IController(controller).treasury(),
                    _wavax
                );
            }
            if (_usdte > 0){
                IERC20(usdte).safeTransfer(
                    IController(controller).treasury(),
                    _usdte
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngAvaxUsdtE";
    }
}