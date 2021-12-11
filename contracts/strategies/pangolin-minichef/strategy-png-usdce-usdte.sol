pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngUsdcEUsdtELp is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 2;

    // Token addresses
    address public png_usdce_usdte_lp = 0xc13E562d92F7527c4389Cd29C67DaBb0667863eA;
    address public usdce = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
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
            png_usdce_usdte_lp,
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

            _swapPangolin(png, usdce, _png.div(2));    
            _swapPangolin(png, usdte, _png.div(2)); 
        }


        // Adds in liquidity for USDCe/USDTe
        uint256 _usdce = IERC20(usdce).balanceOf(address(this));
        uint256 _usdte = IERC20(usdte).balanceOf(address(this));

        if (_usdce > 0 && _usdte > 0) {
            IERC20(usdce).safeApprove(pangolinRouter, 0);
            IERC20(usdce).safeApprove(pangolinRouter, _usdce);

            IERC20(usdte).safeApprove(pangolinRouter, 0);
            IERC20(usdte).safeApprove(pangolinRouter, _usdte);

            IPangolinRouter(pangolinRouter).addLiquidity(
                usdce,
                usdte,
                _usdce,
                _usdte,
                0,
                0,
                address(this),
                now + 60
            );

            _usdce = IERC20(usdce).balanceOf(address(this));
            _usdte = IERC20(usdte).balanceOf(address(this));
            
            // Donates DUST
            if (_usdce > 0){
                IERC20(usdce).transfer(
                    IController(controller).treasury(),
                    _usdce
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
        return "StrategyPngUsdcEUsdtELp";
    }
}