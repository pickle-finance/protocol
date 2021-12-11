pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngUsdcEDaiELp is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 11;

    // Token addresses
    address public png_usdce_daie_lp = 0x221Caccd55F16B5176e14C0e9DBaF9C6807c83c9;
    address public usdce = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
    address public daie = 0xd586E7F844cEa2F87f50152665BCbc2C279D8d70;

    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            png_usdce_daie_lp,
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
            _swapPangolin(png, daie, _png.div(2)); 
        }

        // Adds in liquidity for USDCe/DAIe
        uint256 _usdce = IERC20(usdce).balanceOf(address(this));
        uint256 _daie = IERC20(daie).balanceOf(address(this));

        if (_usdce > 0 && _daie > 0) {
            IERC20(usdce).safeApprove(pangolinRouter, 0);
            IERC20(usdce).safeApprove(pangolinRouter, _usdce);

            IERC20(daie).safeApprove(pangolinRouter, 0);
            IERC20(daie).safeApprove(pangolinRouter, _daie);

            IPangolinRouter(pangolinRouter).addLiquidity(
                usdce,
                daie,
                _usdce,
                _daie,
                0,
                0,
                address(this),
                now + 60
            );

            _usdce = IERC20(usdce).balanceOf(address(this));
            _daie = IERC20(daie).balanceOf(address(this));
            
            // Donates DUST
            if (_usdce > 0){
                IERC20(usdce).transfer(
                    IController(controller).treasury(),
                    _usdce
                );
            }
            if (_daie > 0){
                IERC20(daie).safeTransfer(
                    IController(controller).treasury(),
                    _daie
                );
            }
        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngUsdcEDaiELp";
    }
}