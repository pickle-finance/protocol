pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngUsdcEDaiEMiniLp is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 11;

    // Token addresses
    address public Png_USDCE_DAIE_lp = 0x221Caccd55F16B5176e14C0e9DBaF9C6807c83c9;
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
            Png_USDCE_DAIE_lp,
            _governance,
            _strategist,
            _controller,
            _timelock
        )
    {}
    // **** State Mutations ****

  function harvest() public override onlyBenevolent {
        // Anyone can harvest it at any given time.
        // I understand the possibility of being frontrun
        // But AVAX is a dark forest, and I wanna see how this plays out
        // i.e. will be be heavily frontrunned?
        //      if so, a new strategy will be deployed.

        // Collects Png tokens
        IMiniChef(miniChef).harvest(poolId, address(this));

        uint256 _png = IERC20(png).balanceOf(address(this));
        if (_png > 0) {
            // 10% is sent to treasury
            uint256 _keep = _png.mul(keep).div(keepMax);
            uint256 _amount = _png.sub(_keep).div(2);
            if (_keep > 0) {
                _takeFeePngToSnob(_keep);
            }
            IERC20(png).safeApprove(pangolinRouter, 0);
            IERC20(png).safeApprove(pangolinRouter, _png.sub(_keep));

            _swapPangolin(png, usdce, _amount);    
            _swapPangolin(png, daie, _amount); 
        }


        // Adds in liquidity for USDCE/DAIE
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
        return "StrategyPngUsdcEDaiEMiniLp";
    }
}