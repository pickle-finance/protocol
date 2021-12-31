pragma solidity ^0.6.7;

import "../strategy-png-minichef-farm-base.sol";

contract StrategyPngUsdcEMim is StrategyPngMiniChefFarmBase {
    uint256 public _poolId = 38;

    // Token addresses
    address public png_usdce_mim_lp = 0xE75eD6E50e3e2dc6b06FAf38b943560BD22e343B;
    address public usdce = 0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664;
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
            png_usdce_mim_lp,
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

            // swap half PNG for USDCe
            IERC20(png).safeApprove(pangolinRouter, 0);
            IERC20(png).safeApprove(pangolinRouter, _png);

            _swapPangolin(png, usdce, _png.div(2));  

            // swap the other half for mim, but this needs a special path
            address [] memory path = new address[](3);
            path[0] = png; 
            path[1] = usdce; 
            path[2] = mim;
            IERC20(png).safeApprove(pangolinRouter, 0);
            IERC20(png).safeApprove(pangolinRouter, _png);
            _swapPangolinWithPath(path, _png.div(2)); 
        }


        // Adds in liquidity for USDCE/MIM
        uint256 _usdce = IERC20(usdce).balanceOf(address(this));
        uint256 _mim = IERC20(mim).balanceOf(address(this));

        if (_usdce > 0 && _mim > 0) {
            IERC20(usdce).safeApprove(pangolinRouter, 0);
            IERC20(usdce).safeApprove(pangolinRouter, _usdce);

            IERC20(mim).safeApprove(pangolinRouter, 0);
            IERC20(mim).safeApprove(pangolinRouter, _mim);

            IPangolinRouter(pangolinRouter).addLiquidity(
                usdce,
                mim,
                _usdce,
                _mim,
                0,
                0,
                address(this),
                now + 60
            );

            _usdce = IERC20(usdce).balanceOf(address(this));
            _mim = IERC20(mim).balanceOf(address(this));
            
            // Donates DUST
            if (_usdce > 0){
                IERC20(usdce).transfer(
                    IController(controller).treasury(),
                    _usdce
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
        return "StrategyPngUsdcEMim";
    }
}