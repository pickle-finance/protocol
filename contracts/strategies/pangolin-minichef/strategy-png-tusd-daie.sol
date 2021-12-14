pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngTusdDaiEMiniLp is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 43;

    // Token addresses
    address public Png_TUSD_DAIE_lp = 0x11cb8967c9CEBC2bC8349ad612301DaC843669ea;
    address public tusd = 0x1C20E891Bab6b1727d14Da358FAe2984Ed9B59EB;
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
            Png_TUSD_DAIE_lp,
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

            _swapPangolin(png, tusd, _png.div(2));    
            _swapPangolin(png, daie, _png.div(2)); 
        }


        // Adds in liquidity for TUSD/DAIE
        uint256 _tusd = IERC20(tusd).balanceOf(address(this));

        uint256 _daie = IERC20(daie).balanceOf(address(this));

        if (_tusd > 0 && _daie > 0) {
            IERC20(tusd).safeApprove(pangolinRouter, 0);
            IERC20(tusd).safeApprove(pangolinRouter, _tusd);

            IERC20(daie).safeApprove(pangolinRouter, 0);
            IERC20(daie).safeApprove(pangolinRouter, _daie);

            IPangolinRouter(pangolinRouter).addLiquidity(
                tusd,
                daie,
                _tusd,
                _daie,
                0,
                0,
                address(this),
                now + 60
            );

            _tusd = IERC20(tusd).balanceOf(address(this));
            _daie = IERC20(daie).balanceOf(address(this));
            // Donates DUST
            if (_tusd > 0){
                IERC20(tusd).transfer(
                    IController(controller).treasury(),
                    _tusd
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
        return "StrategyPngTusdDaiEMiniLp";
    }
}