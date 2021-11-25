pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngUsdcEPngMiniLp is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 1;

    // Token addresses
    address public Png_USDCe_Png_lp = 0xC33Ac18900b2f63DFb60B554B1F53Cd5b474d4cd;
    address public usdce = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;


    constructor(
        address _governance,
        address _strategist,
        address _controller,
        address _timelock
    )
        public
        StrategyPngMiniChefFarmBase(
            _poolId,
            Png_USDCe_Png_lp,
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
        }

       

        // Adds in liquidity for USDCe/PNG
        _png = IERC20(png).balanceOf(address(this));
        uint256 _usdce = IERC20(usdce).balanceOf(address(this));

        if (_png > 0 && _usdce > 0) {
            IERC20(png).safeApprove(pangolinRouter, 0);
            IERC20(png).safeApprove(pangolinRouter, _png);

            IERC20(usdce).safeApprove(pangolinRouter, 0);
            IERC20(usdce).safeApprove(pangolinRouter, _usdce);

            IPangolinRouter(pangolinRouter).addLiquidity(
                png,
                usdce,
                _png,
                _usdce,
                0,
                0,
                address(this),
                now + 60
            );

            _png = IERC20(png).balanceOf(address(this));
            _usdce = IERC20(usdce).balanceOf(address(this));
            // Donates DUST
            if (_png > 0){
                IERC20(png).transfer(
                    IController(controller).treasury(),
                    _png
                );
            }
            if (_usdce > 0){
                IERC20(usdce).safeTransfer(
                    IController(controller).treasury(),
                    _usdce
                );
            }

        }

        _distributePerformanceFeesAndDeposit();
    }

    // **** Views ****

    function getName() external pure override returns (string memory) {
        return "StrategyPngUsdcEPngMiniLp";
    }
}